const version = '0.1.0';
export const baseURL = `https://github.com/replicantzk/monorepo/releases/download/v${version}`
export const releaseFiles = {
  'Windows': `Replicant+Worker_${version}_x64-setup.exe`,
  'Mac Apple': `Replicant.Worker_${version}_aarch64.dmg`,
  'Mac Intel': `Replicant.Worker_${version}_x64.dmg`,
  'Linux .AppImage': `replicant-worker_${version}_amd64.AppImage`,
  'Linux .deb': `replicant-worker_${version}_amd64.deb`
};
