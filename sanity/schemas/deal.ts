import { defineField, defineType } from 'sanity'

export default defineType({
  name: 'deal',
  title: "Today's Deal",
  type: 'document',
  fields: [
    defineField({ name: 'label',           title: 'Product Label',    type: 'string' }),
    defineField({ name: 'originalPrice',   title: 'Original Price (₹)', type: 'number' }),
    defineField({ name: 'salePrice',       title: 'Sale Price (₹)',   type: 'number' }),
    defineField({ name: 'discountPercent', title: 'Discount %',       type: 'number' }),
    defineField({
      name: 'colorHex', title: 'Card Color', type: 'string',
      description: 'Hex color e.g. #3B82F6',
    }),
    defineField({
      name: 'product', title: 'Linked Product', type: 'reference',
      to: [{ type: 'product' }],
      options: { disableNew: true },
    }),
    defineField({ name: 'active',    title: 'Active',     type: 'boolean',  initialValue: true }),
    defineField({ name: 'expiresAt', title: 'Expires At', type: 'datetime' }),
  ],
  preview: {
    select: { title: 'label', subtitle: 'discountPercent' },
    prepare: ({ title, subtitle }: { title: string; subtitle: number }) => ({
      title,
      subtitle: subtitle ? `${subtitle}% off` : '',
    }),
  },
})
