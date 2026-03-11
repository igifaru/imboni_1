export const validators = {
  isPhone:    (v: string) => /^\+?[0-9]{9,15}$/.test(v),
  isEmail:    (v: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
  isUUID:     (v: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v),
  isNotEmpty: (v: string) => typeof v === 'string' && v.trim().length > 0,
  minLength:  (v: string, n: number) => typeof v === 'string' && v.length >= n,
  maxLength:  (v: string, n: number) => typeof v === 'string' && v.length <= n,
};
