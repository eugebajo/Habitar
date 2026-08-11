# Habitar Internal Test Checklist

## Core Flow

- [ ] Create an adult account.
- [ ] Create a family.
- [ ] Create child and teen profiles.
- [ ] Create a routine for one profile.
- [ ] Add and review routine steps.
- [ ] Open the child mode.
- [ ] Start the routine.
- [ ] Complete each step.
- [ ] Use help, pause and more-time actions.
- [ ] Finish the routine.
- [ ] Review progress.
- [ ] Generate and open the PDF report.
- [ ] Schedule a routine with a time and confirm Android local reminder behavior.
- [ ] Pause or complete a routine and confirm reminders do not keep firing for that routine.
- [ ] Log out and log in again.
- [ ] Confirm profile isolation between child and teen.
- [ ] Confirm web/mobile data consistency when Supabase credentials are used.

## Known Limitations During Internal Test

- Custom SMTP is not configured.
- Password recovery email delivery is not production-ready.
- Family invitation email delivery is not implemented.
- Multiadult invitation acceptance still needs final end-to-end validation.
- Native smartwatch integration is not implemented.
- Multi-family switching is limited during this test.
- Routine save is not yet transactional; if a network error happens while saving steps, retry the routine edit.
