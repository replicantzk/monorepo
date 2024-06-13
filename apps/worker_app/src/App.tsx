import { BrowserRouter, Routes, Route } from "react-router-dom";
import Header from "./components/Header";
import Models from "./views/Models";
import Settings from "./views/Settings";
import Worker from "./views/Worker";

export default function App() {
  return (
    <div>
      <BrowserRouter>
        <Header />
        <div className="p-8">
          <Routes>
            <Route path="/" element={<Worker />} />
            <Route path="/models" element={<Models />} />
            <Route path="/settings" element={<Settings />} />
          </Routes>
        </div>
      </BrowserRouter>
    </div>
  );
}
