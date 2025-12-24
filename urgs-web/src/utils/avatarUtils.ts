/**
 * Generate a consistent color based on a string (e.g., username or ID)
 */
const stringToColor = (str: string) => {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    const c = (hash & 0x00ffffff).toString(16).toUpperCase();
    return '#' + '00000'.substring(0, 6 - c.length) + c;
};

/**
 * Generate a simple SVG avatar data URI
 */
export const generateAvatar = (seed: string | number) => {
    const seedStr = String(seed);
    const color = stringToColor(seedStr);
    const initial = seedStr.slice(0, 1).toUpperCase();

    // Create a simple SVG
    const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <rect width="100" height="100" fill="${color}" />
        <text x="50" y="50" dy=".1em" fill="#ffffff" font-family="Arial" font-size="50" text-anchor="middle" dominant-baseline="middle">
            ${initial}
        </text>
    </svg>
    `.trim();

    // Convert to Data URI
    return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
};

/**
 * Get avatar URL, converting DiceBear/Unsplash to local fallback if needed
 * Also handles relative paths correction
 */
export const getAvatarUrl = (originalUrl?: string | null, seed?: string | number) => {
    // If no URL, generate one
    if (!originalUrl) {
        return generateAvatar(seed || 'User');
    }

    // Replace external services with local generator (for internal network compliance)
    if (originalUrl.includes('dicebear.com') || originalUrl.includes('unsplash.com')) {
        return generateAvatar(seed || 'User');
    }

    // Handle relative paths (e.g. "profile/...")
    // Assuming API is proxied at /api or root, adjust based on deployment
    // If it starts with 'profile/', prepend '/' to make it absolute from domain root
    if (originalUrl.startsWith('profile/')) {
        return '/' + originalUrl;
    }

    return originalUrl;
};
