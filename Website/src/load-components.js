const components = [
  'Symbols',
  'Nav',
  'Hero',
  'FileFormats',
  'Features',
  'HowItWorks',
  'Templates',
  'Privacy',
  'FAQ',
  'CTA',
  'Footer',
];

const root = document.getElementById('page-root');

async function loadComponent(name) {
  const response = await fetch(`./src/components/${name}.html`);
  if (!response.ok) {
    throw new Error(`Could not load ${name}.html`);
  }
  return response.text();
}

try {
  const html = await Promise.all(components.map(loadComponent));
  root.innerHTML = html.join('\n');
  window.dispatchEvent(new CustomEvent('healther-components-loaded'));
} catch (error) {
  root.innerHTML = `
    <main class="container" style="padding:48px 28px">
      <h1 class="display">healther</h1>
      <p>Could not load the marketing page components.</p>
    </main>
  `;
  console.error(error);
}
