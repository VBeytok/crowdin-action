## How to use
```yaml
name: Crowdin Action

# Controls when the action will run. Triggers the workflow on push events
# but only for the master branch
on:
  push:
    branches: [ master ]

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  # This workflow contains a single job called "build"
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:

    # To use this repository's private action, you must check out the repository
    - name: Checkout
      uses: actions/checkout@v2

    - name: crowdin upload
      uses: VBeytok/crowdin-action@master
      with:
        upload_translations: true
        download_translations: true
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        CROWDIN_PROJECT_ID: ${{ secrets.CROWDIN_PROJECT_ID }}
        CROWDIN_PERSONAL_TOKEN: ${{ secrets.CROWDIN_PERSONAL_TOKEN }}
```
