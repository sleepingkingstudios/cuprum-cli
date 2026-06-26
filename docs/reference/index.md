---
breadcrumbs:
  - name: Documentation
    path: '/'
version: '*'
---

{% assign root_namespace = site.namespaces | where: "version", page.version | first %}

# {{ site.project_metadata.name }}

{% include reference/namespace.md label=false namespace=root_namespace %}
