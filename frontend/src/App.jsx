import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import PlanningYears from './pages/PlanningYears';
import ReferenceData from './pages/ReferenceData';

function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/planning-years" element={<PlanningYears />} />
          <Route path="/reference" element={<ReferenceData />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}

export default App;
