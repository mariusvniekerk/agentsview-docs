import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://agentsview.io',
  integrations: [
    starlight({
      title: 'AgentsView',
      disable404Route: false,
      components: {
        ThemeSelect: './src/components/EmptyThemeSelect.astro',
        Header: './src/components/Header.astro',
        Footer: './src/components/Footer.astro',
      },
      social: {
        github: 'https://github.com/wesm/agentsview',
        discord: 'https://discord.gg/fDnmxB8Wkq',
      },
      customCss: ['./src/styles/custom.css'],
      expressiveCode: {
        themes: ['dracula'],
        styleOverrides: {
          copyButton: {
            visible: true,
          },
        },
      },
      head: [
        {
          tag: 'script',
          attrs: { src: '/lightbox.js', defer: true },
        },
        {
          tag: 'meta',
          attrs: {
            property: 'og:type',
            content: 'website',
          },
        },
        {
          tag: 'meta',
          attrs: {
            property: 'og:site_name',
            content: 'AgentsView',
          },
        },
        {
          tag: 'meta',
          attrs: {
            property: 'og:image',
            content: 'https://agentsview.io/og-image.png',
          },
        },
        {
          tag: 'meta',
          attrs: {
            property: 'og:image:width',
            content: '1200',
          },
        },
        {
          tag: 'meta',
          attrs: {
            property: 'og:image:height',
            content: '630',
          },
        },
        {
          tag: 'meta',
          attrs: {
            name: 'twitter:card',
            content: 'summary_large_image',
          },
        },
        {
          tag: 'meta',
          attrs: {
            name: 'twitter:image',
            content: 'https://agentsview.io/og-image.png',
          },
        },
      ],
      sidebar: [
        { label: 'Quick Start', slug: 'quickstart' },
        { label: 'Usage Guide', slug: 'usage' },
        { label: 'Chat Import', slug: 'chat-import' },
        { label: 'Session Insights', slug: 'insights' },
        { label: 'CLI Reference', slug: 'commands' },
        { label: 'Configuration', slug: 'configuration' },
        { label: 'Remote Access', slug: 'remote-access' },
        { label: 'PostgreSQL Sync', slug: 'pg-sync' },
        { label: 'Changelog', slug: 'changelog' },
      ],
    }),
  ],
});
