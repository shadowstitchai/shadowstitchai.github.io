---
title: Open Coutto Sew
layout: page
permalink: /en/coutto/
description: Open Coutto Sew in the app, or download it from the App Store.
lang: en
---

Open Coutto Sew in the app, or download it from the App Store.

{% assign store_url = site.data.jade.app_store_url | strip %}
{% if store_url != "" %}
<p><a class="button" href="{{ store_url }}">Get it on the App Store</a></p>
{% else %}
<p>Coming soon to the App Store</p>
{% endif %}

<p><a href="coutto://">Already installed? Open the app</a></p>

If it doesn't open, make sure Coutto Sew is installed, or try again later.
