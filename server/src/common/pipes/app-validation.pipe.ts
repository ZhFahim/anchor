import {
  HttpException,
  Injectable,
  PipeTransform,
  ValidationPipe,
  type ArgumentMetadata,
} from '@nestjs/common';
import type { ValidationError } from 'class-validator';
import { coded } from '../errors/coded';
import { ErrorCode } from '../errors/error-code';
import { rejectsUnknownFields } from '../decorators/reject-unknown-fields.decorator';

export interface FieldError {
  field: string;
  rules: string[];
}

export function fieldErrorsOf(
  errors: readonly ValidationError[],
  parent = '',
): FieldError[] {
  return errors.flatMap((error) => {
    const field = parent ? `${parent}.${error.property}` : error.property;
    const own = error.constraints
      ? [{ field, rules: Object.keys(error.constraints) }]
      : [];
    return [...own, ...fieldErrorsOf(error.children ?? [], field)];
  });
}

class CodedValidationPipe extends ValidationPipe {
  createExceptionFactory() {
    const toException = super.createExceptionFactory();
    return (errors: ValidationError[] = []) => {
      const exception = coded(
        toException(errors) as HttpException,
        ErrorCode.VALIDATION_FAILED,
      );
      Object.assign(exception.getResponse() as object, {
        fields: fieldErrorsOf(errors),
      });
      return exception;
    };
  }
}

/** Strips unknown fields, except on DTOs marked `@RejectUnknownFields`. */
@Injectable()
export class AppValidationPipe implements PipeTransform {
  private readonly tolerant = new CodedValidationPipe({
    whitelist: true,
    transform: true,
  });

  private readonly strict = new CodedValidationPipe({
    whitelist: true,
    transform: true,
    forbidNonWhitelisted: true,
  });

  transform(value: unknown, metadata: ArgumentMetadata): Promise<unknown> {
    const pipe = rejectsUnknownFields(metadata.metatype)
      ? this.strict
      : this.tolerant;
    return pipe.transform(value, metadata);
  }
}
