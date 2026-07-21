import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { DictionaryModule } from './dictionary/dictionary.module';
import { GaugeRecordsModule } from './gauge-records/gauge-records.module';
import { GaugeTargetsModule } from './gauge-targets/gauge-targets.module';
import { HealthModule } from './health/health.module';
import { LibraryModule } from './library/library.module';
import { PatternsModule } from './patterns/patterns.module';
import { ProfileModule } from './profile/profile.module';
import { ProjectsModule } from './projects/projects.module';
import { SkillsModule } from './skills/skills.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      // e2e specs stub auth via direct process.env mutation (e.g. DEV_AUTH_USER_ID).
      // If a local .env file exists, @nestjs/config's file-sourced snapshot takes
      // precedence over those runtime mutations for the same key, silently breaking
      // test isolation. Tests should only ever see their own explicit env stubs.
      ignoreEnvFile: process.env.NODE_ENV === 'test',
    }),
    AuthModule,
    DatabaseModule,
    DictionaryModule,
    GaugeRecordsModule,
    GaugeTargetsModule,
    HealthModule,
    LibraryModule,
    ProfileModule,
    ProjectsModule,
    PatternsModule,
    SkillsModule,
  ],
})
export class AppModule {}
