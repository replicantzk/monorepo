import React from "react";
import Link from "next/link";
import { useRouter } from "next/router";

const DownloadButton = ({ name, href, forward = null }) => {
  const router = useRouter();

  const handleForward = () => {
    if (forward !== null) {
      router.push(forward);
    }
  };

  return (
    <Link
      key={name}
      href={href}
      onClick={handleForward}
      className="btn btn-primary m-2"
    >
      {name}
    </Link>
  );
};

export default DownloadButton;
