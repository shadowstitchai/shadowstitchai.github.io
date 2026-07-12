# Shadow Stitch Website

Jekyll site for 北京暗线科技有限公司 / Beijing Shadow Stitch Technology Co., Ltd., built from the Serif theme structure.

## Local development

```sh
bundle install
bundle exec jekyll serve
```

## Deploy to Aliyun OSS

One-time setup (Ruby gems + [ossutil](https://help.aliyun.com/document_detail/120075.html)):

```sh
chmod +x scripts/setup.sh scripts/deploy-oss.sh
./scripts/setup.sh
```

Edit `.env` with your bucket and AccessKey credentials (see `.env.example`).

Build the site and sync `_site/` to OSS:

```sh
./scripts/deploy-oss.sh
```

**OSS static website hosting** (Aliyun console, one-time):

1. Enable **Static Website Hosting** on the bucket.
2. Set **Default homepage** to `index.html` and **Default 404 page** to `404.html`.
3. Bind your custom domain (e.g. `shadowstitch.cn`) and enable HTTPS.

The deploy script uses `ossutil sync --delete` so the bucket mirrors the latest build.
