import { defineField, defineType } from 'sanity'

export default defineType({
  name: 'homeBanner',
  title: 'Home Banner',
  type: 'document',
  fields: [
    defineField({ name: 'badge',     title: 'Badge Text',       type: 'string' }),
    defineField({ name: 'title',     title: 'Title',            type: 'string' }),
    defineField({ name: 'subtitle',  title: 'Subtitle',         type: 'string' }),
    defineField({ name: 'ctaLabel',  title: 'CTA Button Label', type: 'string' }),
    defineField({
      name: 'ctaAction', title: 'CTA Action', type: 'string',
      options: { list: ['shop', 'design', 'deal'] },
    }),
    defineField({
      name: 'ctaColor', title: 'CTA Color', type: 'string',
      options: { list: ['purple', 'blue', 'orange'] },
    }),
    defineField({
      name: 'image', title: 'Banner Image', type: 'image',
      options: { hotspot: true },
    }),
    defineField({ name: 'order',  title: 'Display Order', type: 'number', initialValue: 1 }),
    defineField({ name: 'active', title: 'Active',        type: 'boolean', initialValue: true }),
  ],
  orderings: [
    { title: 'Display Order', name: 'orderAsc', by: [{ field: 'order', direction: 'asc' }] },
  ],
  preview: {
    select: { title: 'title', subtitle: 'badge', media: 'image' },
  },
})
