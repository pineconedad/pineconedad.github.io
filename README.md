# pineconedad.github.io

The design is adapted from [Jon Barron's website](https://jonbarron.info/) and
[Leonid Keselman's Jekyll fork](https://github.com/leonidk/leonidk.github.io).

## Maintenance

Profile details live in `_data/profile.yml`. Add one Markdown file per item in
`_publications/`, `_projects/`, or `_experience/`. The first body paragraph is
shown on the homepage.

Put original images in `assets/images/`. PNG is preferred; JPG/JPEG, WebP, and
GIF are also supported. Generate homepage thumbnails with:

```sh
scripts/make_thumbnails.sh
```

Store local papers, posters, slides, and the CV under `assets/pdfs/`. To preview
the site locally, run `bundle exec jekyll serve`.
