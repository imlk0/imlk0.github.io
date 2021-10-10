# imlk's blog

👋 hello, welcome to here.

This is repository of my static blog, which was originally built using [hexo](https://github.com/hexojs/hexo), but has now been migrated to [hugo](https://github.com/gohugoio/hugo/).

If you are here because you would like to read my blog, please follow this link: https://blog.imlk.top/


## Some tips for myself

- You may be curious about those symbolic link files called `images` and `objects`.
  Basically, there are located at:
  ```text
  /images
  /objects
  /content/posts/images
  /content/posts/objects
  ```
  These are not hugo generated files. Just a compromise to keep both the local markdown editor and the resource file url working correctly.
  All the static file (e.g. `images` and `objects` should be placed in `/static`)

  However, hugo won't ignore these symbolic link files, cause it copy them multiple times. So remember to modify `ignoreFiles` in `config.yaml` after create new symbolic link files.

  ```yaml
  ignoreFiles:
    - 'posts/images'
    - 'posts/objects'
    - 'images'
    - 'objects'
  ```