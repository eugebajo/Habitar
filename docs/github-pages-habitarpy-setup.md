# GitHub Pages setup for habitarpy.com

The public legal/marketing site lives in:

```text
sites/habitarpy
```

It includes:

- `https://habitarpy.com/`
- `https://habitarpy.com/privacy/`
- `https://habitarpy.com/terms/`

## GitHub setup

1. Go to the repository on GitHub.
2. Open `Settings`.
3. Open `Pages`.
4. Under `Build and deployment`, choose `GitHub Actions`.
5. Save.
6. Run the workflow `Habitarpy Pages` if it did not run automatically.

## Namecheap DNS records

In Namecheap, open `Domain List > habitarpy.com > Manage > Advanced DNS`.

Remove parked/default records that conflict with `@` or `www`.

Add these records for the apex domain:

```text
Type: A Record
Host: @
Value: 185.199.108.153
TTL: Automatic
```

```text
Type: A Record
Host: @
Value: 185.199.109.153
TTL: Automatic
```

```text
Type: A Record
Host: @
Value: 185.199.110.153
TTL: Automatic
```

```text
Type: A Record
Host: @
Value: 185.199.111.153
TTL: Automatic
```

Add this record for `www`:

```text
Type: CNAME Record
Host: www
Value: eugebajo.github.io
TTL: Automatic
```

DNS can take up to 24 hours to propagate.

## GitHub custom domain

After DNS is added:

1. Go to `Settings > Pages`.
2. Under `Custom domain`, enter:

```text
habitarpy.com
```

3. Save.
4. When GitHub allows it, enable `Enforce HTTPS`.

Official reference:

`https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site`
