---
title: 打开纽扣纸样
layout: page
permalink: /coutto/
description: 在 App 中打开纽扣纸样，或前往 App Store 下载。
lang: zh-CN
---

在 App 中打开纽扣纸样，或前往 App Store 下载。

{% assign store_url = site.data.jade.app_store_url | strip %}
{% if store_url != "" %}
<p><a class="button" href="{{ store_url }}">前往 App Store</a></p>
{% else %}
<p>App 即将上架 App Store</p>
{% endif %}

<p><a href="coutto://">已安装？打开 App</a></p>

若未自动打开，请确认已安装纽扣纸样，或稍后再试。
