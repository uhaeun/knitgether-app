import {
  ProfileResponseDto,
  UserProfileModel,
  toProfileResponse,
} from '../profile/profile-response.dto';

export type AuthSessionResponseDto = {
  accessToken: string;
  tokenType: 'Bearer';
  profile: ProfileResponseDto;
};

export type AuthUserResponseDto = {
  id: string;
  email: string;
  profile: ProfileResponseDto;
};

export function toAuthSessionResponse(params: {
  accessToken: string;
  profile: UserProfileModel;
}): AuthSessionResponseDto {
  return {
    accessToken: params.accessToken,
    tokenType: 'Bearer',
    profile: toProfileResponse(params.profile),
  };
}

export function toAuthUserResponse(params: {
  id: string;
  email: string;
  profile: UserProfileModel;
}): AuthUserResponseDto {
  return {
    id: params.id,
    email: params.email,
    profile: toProfileResponse(params.profile),
  };
}
