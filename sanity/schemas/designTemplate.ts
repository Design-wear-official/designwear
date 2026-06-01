import { defineField, defineType } from 'sanity'

export default defineType({
  name: 'designTemplate',
  title: 'Design Template',
  type: 'document',
  fields: [
    defineField({
      name: 'templateId', title: 'Template ID', type: 'slug',
      options: { source: 'name' },
    }),
    defineField({ name: 'name',        title: 'Template Name', type: 'string' }),
    defineField({ name: 'description', title: 'Description',   type: 'string' }),
    defineField({
      name: 'category', title: 'Category', type: 'string',
      options: {
        list: ['vintage', 'minimalist', 'sports', 'urban', 'nature', 'corporate', 'artistic', 'funny'],
      },
    }),
    defineField({
      name: 'thumbnail', title: 'Thumbnail', type: 'image',
      options: { hotspot: true },
    }),
    defineField({
      name: 'tags', title: 'Tags', type: 'array',
      of: [{ type: 'string' }],
    }),
    defineField({
      name: 'designData', title: 'Design JSON', type: 'text',
      description: 'JSON string of CustomDesign (baseColor + elements[])',
      rows: 8,
    }),
    defineField({ name: 'active', title: 'Active', type: 'boolean', initialValue: true }),
    defineField({ name: 'order',  title: 'Display Order', type: 'number', initialValue: 1 }),
  ],
  orderings: [
    { title: 'Display Order', name: 'orderAsc', by: [{ field: 'order', direction: 'asc' }] },
  ],
  preview: {
    select: { title: 'name', subtitle: 'category', media: 'thumbnail' },
  },
})
