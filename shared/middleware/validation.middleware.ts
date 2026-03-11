import { Request, Response, NextFunction } from 'express';

type ValidatorFn = (body: Record<string, any>) => string | null;

/** Factory: returns middleware that validates req.body with the given validator function. */
export function validate(validator: ValidatorFn) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const error = validator(req.body);
    if (error) { res.status(422).json({ success: false, error }); return; }
    next();
  };
}

export const required = (...fields: string[]): ValidatorFn =>
  (body) => {
    for (const f of fields) {
      if (!body[f]) return \`Field '\${f}' is required\`;
    }
    return null;
  };
