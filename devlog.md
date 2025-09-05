---
layout: page
title: Devlog
permalink: /devlog/
---

Please consider subscribing to the <a href="/devlog-feed.xml">📡 RSS Feed</a>

{% for entry in site.devlog reversed %}
  <article class="devlog-entry">
    <h3><a href="{{ entry.url | relative_url }}">{{ entry.title }}</a></h3>
    <time>{{ entry.date | date: "%B %d, %Y" }}</time>
    <div class="content">
      {{ entry.content }}
    </div>
  </article>
  <hr>
{% endfor %}