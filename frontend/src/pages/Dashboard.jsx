import { useState, useEffect } from 'react';

const API_BASE = '/api';

export default function Dashboard() {
  const [health, setHealth] = useState(null);
  const [years, setYears] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    async function fetchData() {
      try {
        const [healthRes, yearsRes] = await Promise.all([
          fetch(`${API_BASE}/health`),
          fetch(`${API_BASE}/planning-years`),
        ]);
        if (!cancelled) {
          const healthData = await healthRes.json();
          setHealth(healthData);
          if (yearsRes.ok) {
            const yearsData = await yearsRes.json();
            setYears(yearsData);
          }
        }
      } catch (e) {
        if (!cancelled) setError(e.message);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    fetchData();
    return () => { cancelled = true; };
  }, []);

  if (loading) return <p className="muted">Loading…</p>;
  if (error) return <p className="error">Error: {error}</p>;

  return (
    <div className="dashboard">
      <h1>Dashboard</h1>
      <p className="muted">Year-first planning and cost plan overview.</p>

      <section className="card">
        <h2>API Status</h2>
        <p>
          Backend: <strong>{health?.status === 'ok' ? 'Connected' : 'Unknown'}</strong>
          {health?.service && ` (${health.service})`}
        </p>
      </section>

      <section className="card">
        <h2>Planning Years</h2>
        {years.length === 0 ? (
          <p className="muted">No planning years in the database. Run the DDL and seed scripts first.</p>
        ) : (
          <ul className="year-list">
            {years.map((y) => (
              <li key={y.cost_plan_year_id}>
                <strong>{y.year_name || y.year_code}</strong>
                <span className="badge">{y.status}</span>
                <span className="muted">
                  {new Date(y.start_date).getFullYear()} – {new Date(y.end_date).getFullYear()}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
