# pineconedad.github.io

Personal academic website for Wardat Shams Iqbal.

The design is adapted from [Jon Barron's website](https://jonbarron.info/) and
[Leonid Keselman's Jekyll fork](https://github.com/leonidk/leonidk.github.io).

## Local development

Install the bundle and start Jekyll:

```sh
bundle install
bundle exec jekyll serve
```

The site will be available at `http://127.0.0.1:4000`.

To build without starting a server:

```sh
bundle exec jekyll build
```

## Update site content

Run the content tool and follow its prompts:

```sh
ruby tools/manage_site.rb
```

You can also select an action directly:

```sh
ruby tools/manage_site.rb publication
ruby tools/manage_site.rb project
ruby tools/manage_site.rb profile
```

The tool adds publications and projects to their YAML files. It can also copy
an image from a path on your computer into the correct website folder. The
Projects section stays hidden until `_data/projects.yml` contains an entry.
Review the generated changes, then commit and push them for GitHub Pages to
publish the update.

You can edit the data files directly when that is faster:

| Content | Data file |
| --- | --- |
| Introduction, profile photo, and links | `_data/profile.yml` |
| Publications | `_data/publications.yml` |
| Projects | `_data/projects.yml` |
| Experience | `_data/experiences.yml` |

## Images

| Content | Folder | Accepted formats |
| --- | --- | --- |
| Profile photo | `assets/images/profile/` | PNG, JPG/JPEG, WebP |
| Publication image | `assets/images/publications/` | PNG, JPG/JPEG, WebP, GIF, SVG |
| Project image | `assets/images/projects/` | PNG, JPG/JPEG, WebP, GIF, SVG |

PDF files cannot be used in the `photo` or `image` fields. Export a PDF figure
to PNG or WebP first. GIF and animated WebP files can provide the small moving
previews used on some academic websites.

Every non-empty `photo` or `image` field should use a site path such as:

```yaml
image: "/assets/images/publications/example.webp"
image_alt: "Diagram of the model architecture"
```

Keep an alt-text field with every image so screen readers can describe it.
