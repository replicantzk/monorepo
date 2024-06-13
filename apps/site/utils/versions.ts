const version = '0.1.0';
export const baseURL = `https://replicant-releases.s3.amazonaws.com/v${version}`;
export const releaseFiles = {
  'Linux .deb': `ubuntu-20.04/deb/replicant-worker_${version}_amd64.deb`,
  'Linux .AppImage': `ubuntu-20.04/appimage/replicant-worker_${version}_amd64.AppImage`,
  'Windows': `windows-latest/nsis/Replicant+Worker_${version}_x64-setup.exe`
};
