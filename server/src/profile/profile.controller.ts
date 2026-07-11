import {
  Body,
  Controller,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { ApiAuthGuard } from '../auth/api-auth.guard';
import {
  CurrentUser,
  CurrentUserPayload,
} from '../auth/current-user.decorator';
import { ProfileResponseDto } from './profile-response.dto';
import { SaveProfileDto } from './profile-save.dto';
import { ProfileService } from './profile.service';

@UseGuards(ApiAuthGuard)
@Controller('profile')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get()
  getCurrentProfile(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ProfileResponseDto> {
    return this.profileService.getCurrentProfile(currentUser.id);
  }

  @Patch()
  updateCurrentProfile(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveProfileDto,
  ): Promise<ProfileResponseDto> {
    return this.profileService.updateCurrentProfile(currentUser.id, body);
  }
}
