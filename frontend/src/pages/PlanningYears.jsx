import { useState, useEffect } from 'react';

const API_BASE = '/api';

export default function PlanningYears() {
  const [years, setYears] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    fetch(`${API_BASE}/planning-years`)
      .then((res) => res.json())
      .then((data) => {
        if (!cancelled) setYears(Array.isArray(data) ? data : []);
      })
      .catch((e) => {
        if (!cancelled) setError(e.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => { cancelled = true; };
  }, []);

  if (loading) return <p className="muted">Loading planning years…</p>;
  if (error) return <p className="error">Error: {error}</p>;

  return (
    <div>
      <h1>Planning Years</h1>
      <p className="muted">Select a year to scope all planning and reporting.</p>

      <div className="card table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Year</th>
              <th>Name</th>
              <th>Status</th>
              <th>Start</th>
              <th>End</th>
            </tr>
          </thead>
          <tbody>
            {years.map((y) => (
              <tr key={y.cost_plan_year_id}>
                <td>{y.year_code}</td>
                <td>{y.year_name || '—'}</td>
                <td><span className="badge">{y.status}</span></td>
                <td>{y.start_date ? new Date(y.start_date).toLocaleDateString() : '—'}</td>
                <td>{y.end_date ? new Date(y.end_date).toLocaleDateString() : '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {years.length === 0 && (
          <p className="muted" style={{ padding: '1rem' }}>No planning years found.</p>
        )}
      </div>
    </div>
  );
}
