import { Link } from "react-router-dom";
import { useWorkerStore } from "../stores/worker";

export default function Header() {
  const modelRunning = useWorkerStore((state) => state.modelRunning);
  const running = useWorkerStore((state) => state.running);
  
  return (
    <div className="flex flex-row justify-between p-4 text-center">
      <div className="flex flex-row spacesh-x-4 items-center">
        <img src="/logo.svg" alt="logo" className="h-20 w-20" />
        {running && modelRunning ? (
          <p>Running with {modelRunning}</p>
        ) : (
          <p>Not running</p>
        )}
      </div>
      <div className="flex flex-row space-x-4 items-center">
        <Link to="/">
          <button className="btn btn-primary">Worker</button>
        </Link>
        <Link to="/models">
          <button className="btn btn-primary">Models</button>
        </Link>
        <Link to="/settings">
          <button className="btn btn-primary">Settings</button>
        </Link>
      </div>
    </div>
  );
}
