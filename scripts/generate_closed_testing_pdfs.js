const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const repoRoot = path.resolve(__dirname, '..');
const outputDir = path.join(repoRoot, 'output', 'pdf');
const htmlDir = path.join(repoRoot, 'tmp', 'pdfs');
const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

const docs = [
  ['docs/closed-testing-plan.md', 'habitar-prueba-cerrada-plan.pdf'],
  ['docs/tester-invitation-message.md', 'habitar-mensaje-invitacion-testers.pdf'],
  ['docs/tester-instructions.md', 'habitar-instrucciones-testers.pdf'],
  ['docs/tester-feedback-form.md', 'habitar-formulario-feedback-testers.pdf'],
  ['docs/play-console-final-review-checklist.md', 'habitar-checklist-final-play-console.pdf'],
];

fs.mkdirSync(outputDir, { recursive: true });
fs.mkdirSync(htmlDir, { recursive: true });

function escapeHtml(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function inlineMarkdown(value) {
  return escapeHtml(value)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
}

function markdownToHtml(markdown) {
  const lines = markdown.split(/\r?\n/);
  const html = [];
  let inCode = false;
  let codeLines = [];
  let listType = null;

  function closeList() {
    if (listType) {
      html.push(`</${listType}>`);
      listType = null;
    }
  }

  function closeCode() {
    if (inCode) {
      html.push(`<pre><code>${escapeHtml(codeLines.join('\n'))}</code></pre>`);
      codeLines = [];
      inCode = false;
    }
  }

  for (const line of lines) {
    if (line.trim().startsWith('```')) {
      if (inCode) {
        closeCode();
      } else {
        closeList();
        inCode = true;
        codeLines = [];
      }
      continue;
    }

    if (inCode) {
      codeLines.push(line);
      continue;
    }

    const trimmed = line.trim();
    if (!trimmed) {
      closeList();
      continue;
    }

    const heading = trimmed.match(/^(#{1,4})\s+(.+)$/);
    if (heading) {
      closeList();
      const level = heading[1].length;
      html.push(`<h${level}>${inlineMarkdown(heading[2])}</h${level}>`);
      continue;
    }

    const bullet = trimmed.match(/^-\s+(.+)$/);
    if (bullet) {
      if (listType !== 'ul') {
        closeList();
        listType = 'ul';
        html.push('<ul>');
      }
      html.push(`<li>${inlineMarkdown(bullet[1])}</li>`);
      continue;
    }

    const number = trimmed.match(/^\d+\.\s+(.+)$/);
    if (number) {
      if (listType !== 'ol') {
        closeList();
        listType = 'ol';
        html.push('<ol>');
      }
      html.push(`<li>${inlineMarkdown(number[1])}</li>`);
      continue;
    }

    closeList();
    html.push(`<p>${inlineMarkdown(trimmed)}</p>`);
  }

  closeCode();
  closeList();
  return html.join('\n');
}

function pageTemplate(title, body) {
  return `<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>${escapeHtml(title)}</title>
  <style>
    @page {
      size: A4;
      margin: 18mm 17mm 20mm;
    }
    * {
      box-sizing: border-box;
    }
    body {
      color: #172328;
      font-family: "Segoe UI", Arial, sans-serif;
      font-size: 11.5pt;
      line-height: 1.48;
      margin: 0;
    }
    h1 {
      border-bottom: 2px solid #1f7a5a;
      color: #123129;
      font-size: 24pt;
      line-height: 1.12;
      margin: 0 0 18px;
      padding-bottom: 10px;
    }
    h2 {
      color: #1f5f4a;
      font-size: 16pt;
      margin: 24px 0 8px;
      page-break-after: avoid;
    }
    h3 {
      color: #26383d;
      font-size: 13pt;
      margin: 18px 0 6px;
      page-break-after: avoid;
    }
    h4 {
      color: #26383d;
      font-size: 11.5pt;
      margin: 14px 0 5px;
      page-break-after: avoid;
    }
    p {
      margin: 0 0 9px;
    }
    ul,
    ol {
      margin: 0 0 10px 22px;
      padding: 0;
    }
    li {
      margin: 3px 0;
    }
    code {
      background: #edf5f1;
      border-radius: 4px;
      color: #174935;
      font-family: Consolas, "Courier New", monospace;
      font-size: 10pt;
      padding: 1px 4px;
    }
    pre {
      background: #f5f7f6;
      border: 1px solid #d7e4df;
      border-radius: 8px;
      margin: 10px 0 14px;
      padding: 10px 12px;
      white-space: pre-wrap;
    }
    pre code {
      background: transparent;
      padding: 0;
    }
    .footer {
      border-top: 1px solid #d7e4df;
      color: #6b7b80;
      font-size: 9pt;
      margin-top: 26px;
      padding-top: 8px;
    }
  </style>
</head>
<body>
${body}
<div class="footer">Habitar - paquete de prueba cerrada Android</div>
</body>
</html>`;
}

function printPdf(htmlPath, pdfPath) {
  return new Promise((resolve, reject) => {
    const args = [
      '--headless=new',
      '--disable-gpu',
      '--no-pdf-header-footer',
      `--print-to-pdf=${pdfPath}`,
      `file:///${htmlPath.replaceAll('\\', '/')}`,
    ];
    const child = spawn(chromePath, args, { windowsHide: true });
    let stderr = '';
    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });
    child.on('error', reject);
    child.on('exit', (code) => {
      if (code === 0 && fs.existsSync(pdfPath)) {
        resolve();
      } else {
        reject(new Error(`Chrome failed for ${pdfPath}: ${stderr}`));
      }
    });
  });
}

async function main() {
  for (const [sourceRelative, pdfName] of docs) {
    const sourcePath = path.join(repoRoot, sourceRelative);
    const markdown = fs.readFileSync(sourcePath, 'utf8');
    const title = markdown.split(/\r?\n/).find((line) => line.startsWith('# '))?.replace(/^#\s+/, '') || pdfName;
    const htmlPath = path.join(htmlDir, `${path.basename(pdfName, '.pdf')}.html`);
    const pdfPath = path.join(outputDir, pdfName);
    fs.writeFileSync(htmlPath, pageTemplate(title, markdownToHtml(markdown)), 'utf8');
    await printPdf(htmlPath, pdfPath);
    const size = fs.statSync(pdfPath).size;
    console.log(`${pdfName} ${size} bytes`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
