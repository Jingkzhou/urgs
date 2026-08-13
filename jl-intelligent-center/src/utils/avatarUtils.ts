const COLORS = ['#c94f47', '#2563eb', '#059669', '#7c3aed', '#d97706'];

const escapeSvgText = (value: string) => value
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&apos;');

export const generateAvatar = (seed: string | number) => {
  const value = String(seed || '用户');
  const color = COLORS[Math.abs([...value].reduce((total, character) => total + character.charCodeAt(0), 0)) % COLORS.length];
  const initial = escapeSvgText(value.trim().slice(0, 1).toUpperCase() || '用');
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" fill="${color}"/><text x="50" y="52" fill="#fff" font-family="system-ui" font-size="48" text-anchor="middle" dominant-baseline="middle">${initial}</text></svg>`;
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
};

export const getAvatarUrl = (originalUrl?: string | null, seed?: string | number) => {
  if (!originalUrl || originalUrl.includes('dicebear.com') || originalUrl.includes('unsplash.com')) {
    return generateAvatar(seed || '用户');
  }
  return originalUrl;
};

