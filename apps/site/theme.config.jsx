import Image from 'next/image'

export default {
  logo: 
  <div className="flex flex-row space-x-2 items-center">
    <Image src="/logo.svg" alt="Logo" width={50} height={50} />
    {/* <p>Replicant Network</p> */}
  </div>,
  project: {
    link: "https://github.com/replicantzk/monorepo",
  },
  chat: {
    link: "https://discord.gg/fV84xXVwZJ",
    icon: <Image src="/discord.svg" alt="Discord" width={20} height={20} />,
  },

  useNextSeoProps() {
    return {
      titleTemplate: '%s – Replicant Network',
    }
  }
};
