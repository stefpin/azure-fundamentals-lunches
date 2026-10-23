# Contributing

Thank you for helping make this course better! Azure changes every month, so reports from learners are the best way to
keep the lunches and labs accurate.

## Report a problem

Open an issue and pick the matching template:

- **Lab problem** — a command, script or step does not work. Please include the lab number, the task, the exact command,
  the full error message, your region (`echo $LOCATION`) and your Azure CLI version (`az version`).
- **Content correction** — something in a reading or demo is wrong, unclear or out of date. A link to the current
  documentation helps a lot.
- **Idea** — a topic, demo or lab improvement you would like to see.

Please do **not** paste subscription IDs, tenant names, keys, passwords or connection strings into issues.

## Propose a change

1. Fork the repository and create a branch (`fix/lab-09-probe`, `content/lunch-12-consistency`).
2. Follow [AUTHORING-GUIDE.md](AUTHORING-GUIDE.md) — especially the demo player rules and the lab script conventions.
3. Run the checks:

   ```bash
   python3 tools/validate_demo.py          # interactive demos
   python3 tools/check_links.py            # relative links
   find labs -name '*.sh' -exec bash -n {} \;   # shell syntax
   python3 tools/build_index.py            # if you added or renamed a lunch or lab
   python3 tools/build_site.py             # rebuild the website (needs markdown-it-py)
   ```

4. If you changed a lab, run it end to end in your own subscription (`setup.sh`, the tasks or `solution.sh`,
   `verify.sh`, `cleanup.sh`) and say so in the pull request.
5. Open a pull request that explains what changed and why.

## Ground rules

- Write in your own words; do not copy text from documentation, books or other courses.
- Keep labs independent and safe: everything a lab creates must be removed by its `cleanup.sh`.
- Be kind. Everyone here is learning.
