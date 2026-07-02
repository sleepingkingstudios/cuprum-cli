---
breadcrumbs:
  - name: Documentation
    path: '/'
  - name: Versions
    path: '/versions'
  - name: '0.1'
    path: '/versions/0.1'
version: '0.1'
---

{% assign root_namespace = site.namespaces | where: "version", page.version | first %}

# {{ site.project_metadata.name }}

{% include reference/namespace.md label=false namespace=root_namespace %}
