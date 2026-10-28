---
breadcrumbs:
- name: Documentation
  path: "/"
- name: Versions
  path: "/versions"
- name: Version 0.2
  path: "/versions/0.2"
version: '0.2'
---

{% assign root_namespace = site.namespaces | where: "version", page.version | first %}

# {{ site.project_metadata.name }}

{% include reference/namespace.md label=false namespace=root_namespace %}
