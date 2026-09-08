import {z} from 'zod';
export const roles = ['student', 'representative', 'moderator', 'administrator'];
export const id = z.string().regex(/^[A-Za-z0-9_-]{1,128}$/);
const clean = (max) => z.string().trim().min(1).max(max).refine(s => !/[\x00-\x08\x0B\x0C\x0E-\x1F]/.test(s), 'Invalid control characters');
export const profileSchema = z.object({name: clean(80), enrollment: clean(40), department: clean(80), semester: z.number().int().min(1).max(12), bio: z.string().trim().max(500), skills: z.array(clean(40)).max(12)}).strict();
export const postSchema = z.object({body: clean(3000), communityId: z.union([id, z.literal('')]).default(''), imagePath: z.string().max(250).default('')}).strict();
export const eventSchema = z.object({title: clean(120), description: clean(3000), location: clean(160), startsAt: z.number().int().refine(n => n > Date.now() && n < Date.now()+366*86400000, 'Choose a future date within one year'), communityId: z.union([id,z.literal('')]).default('')}).strict();
export const communitySchema = z.object({name: clean(100), description: clean(600), kind: z.enum(['Club','Department','Community'])}).strict();
export function universityEmail(email, domains) {
  const parts = (email || '').toLowerCase().split('@');
  return parts.length === 2 && parts[0].length > 0 && domains.map(d=>d.trim().toLowerCase()).filter(Boolean).includes(parts[1]);
}
