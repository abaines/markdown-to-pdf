# Markdown to PDF

Creates PDF and HTML files from Markdown using the GitHub (or custom) theme.

## Notable Features:

- Code highlighting
- Tables
- Images (see docs)
- Internal and external links
- Color emoji, typed directly or as shortcodes: 🚀 :tada: 🧪
- Unicode text and symbols: 日本語, 中文, ไทย, العربية, → ✓ € ©
- Pinned base image and npm packages, for more repeatable builds

## About This Fork

This is a fork of [BaileyJM02/markdown-to-pdf](https://github.com/BaileyJM02/markdown-to-pdf).
It takes the same inputs and produces the same outputs,
so the documentation below still applies.

What's different:

- Scripts in the Markdown don't run while the PDF renders.
  Upstream runs them, in a browser inside the action's container.
- The action runs one prebuilt image, pinned by digest in `action.yml`,
  so every run uses exactly the same image.
- PDFs are rendered with Debian's open source Chromium package, not Google Chrome.
  Upstream installs Chrome, which is proprietary,
  and Puppeteer would otherwise download its own browser.
- The base image and npm packages track the latest releases,
  taking each one only once it's at least 7 days old.
  npm packages are locked and installed with `npm ci`, with install scripts turned off.
- The repository's workflows only run when started by hand,
  and every action they use is pinned to a commit SHA.

Things to know:

- Raw HTML in the Markdown is still allowed,
  and it can load remote images and stylesheets while the PDF renders.
  Only convert Markdown you trust.
- The image is frozen.
  It gets no security updates until a new image is published and pinned.
- Pin this action by commit SHA.
  That also pins the image, because `action.yml` names it by digest.

## GitHub Action Inputs

### Input Path

```yaml
with:
  input_path: value
```

(**Required**)
([Path](#path)) or ([File](#file))
The location of the folder containing your .md or .markdown files, or a path to a single .md or .markdown file that you would like to convert.

*Note, previous versions of this action accepted the `input_dir` input. This is still accepted as input for backwards compatibility, but passing a directory as `input_path` now carries out the same functionality.

### Images Directory

```yaml
with:
  images_dir: value
```

([Path](#path))
The location of the folder containing your images, this should be the route of all images. So of you had images located
at `images/about/file.png` and `images/something-else/file.png` you would pass the value `images`.

### Output Directory

```yaml
with:
  output_dir: value
```

([Path](#path))
The location of the folder you want to place the built files.

### Image Import Prefix

```yaml
with:
  image_import: value
```

([String](#string))
The path you use to import your images that can be replaced with the server URL. For example if you
had `<img src="./images/something-else/file.">` you would pass `./images` as this is replaced
by `https://localhost:3000` during the build process.

### Build HTML

```yaml
with:
  build_html: value
```

([Boolean](#boolean))
Whether to also create a .html file.

### Build PDF

```yaml
with:
  build_pdf: value
```

([Boolean](#boolean))
Whether to also create a .pdf file (defaults to `true`. After all, this is the intended behaviour).

### CSS Theme

```yaml
with:
  theme: value
```

([File](#file))
The location of the CSS file you want to use as the theme.

```yaml
with:
  extend_default_theme: value
```

([Boolean](#boolean))
Whether to extend your custom CSS file with the default theme

### Highlight CSS Theme

```yaml
with:
  highlight_theme: value
```

([File](#file))
The location of the CSS file you want to use as the code snipped highlight theme.

### HTML/Mustache Template file

```yaml
with:
  template: value
```

([File](#file))
The location of the HTML/Mustache file you want to use as the HTML template.

### Table Of Contents

```yaml
with:
  table_of_contents: value
```

([Boolean](#boolean))
Whether a table of contents should be generated

## Input Types

A few pieces to describe what input each value expects.

### Path

A path will most likely be from your repository's route, it should not be prefixed or suffixed with a `/`. The path
should look like so `docs/topic/featureDocs` or `writing/category`.

### String

A string could be anything, and using `YAML` (or `YML`) does not need to be encased in quotes.

### Boolean

This should be either `true` or `false`.

### File

This should be the direct path to a file, it should not be prefixed with a `/`. An example: `styles/markdown-theme.css`.

## Usage Examples

An example of a workflow for some documentation.
Replace each `<...>` placeholder;
pin every action to a full commit SHA, with the release it came from in a comment.

````yml
# .github/workflows/convert-to-pdf.yml

name: Docs to PDF
# This workflow is triggered on pushes to the repository.
on:
  push:
    branches:
      - main
    # Paths can be used to only trigger actions when you have edited certain files, such as a file within the /docs directory
    paths:
      - 'docs/**.md'
      - 'docs/images/**'

# Rendering only needs to read the repository.
permissions:
  contents: read

jobs:
  converttopdf:
    name: Build PDF
    # Pin an Ubuntu release rather than ubuntu-latest, so the runner doesn't change under you.
    runs-on: ubuntu-<version>
    steps:
      - uses: actions/checkout@<commit SHA> # <release>
        with:
          # Don't keep the token where later steps, including the render, could read it.
          persist-credentials: false
      # Pinning this fork's commit also pins the image, by digest.
      - uses: abaines/markdown-to-pdf@<commit SHA> # <fork release tag>
        with:
          input_path: docs
          # Keep the trailing slash: without it, an existing folder gets files named like pdfsREADME.pdf
          output_dir: pdfs/
          images_dir: docs/images
          # for example <img src="./images/file-name.png">
          image_import: ./images
          # Default is true, can set to false to only get PDF files
          build_html: false
      - uses: actions/upload-artifact@<commit SHA> # <release>
        with:
          name: docs
          path: pdfs

````

## Contributions

Any contributions are helpful, please make a pull-request. If you would like to discuses a new feature, please create an
issue first.
