import { IsEnum } from 'class-validator';
import { ApiTokenScope } from '../../generated/prisma/enums';

export class SetApiTokenScopeDto {
  @IsEnum(ApiTokenScope)
  scope: ApiTokenScope;
}
