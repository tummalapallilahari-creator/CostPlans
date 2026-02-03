import { useState, useEffect } from 'react';

const API_BASE = '/api/reference';

const ENDPOINTS = [
  { key: 'countries', label: 'Countries', path: '/countries' },
  { key: 'grades', label: 'Grades', path: '/grades' },
  { key: 'post-categories', label: 'Post Categories', path: '/post-categories' },
  { key: 'umoja-classes', label: 'Umoja Classes', path: '/umoja-classes' },
  { key: 'cost-categories', label: 'Cost Categories', path: '/cost-categories' },
  { key: 'duty-stations', label: 'Duty Stations', path: '/duty-stations' },
];

export default function ReferenceData() {
  const [active, setActive] = useState('countries');
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const current = ENDPOINTS.find((e) => e.key === active);

  useEffect(() => {
    if (!current) return;
    let cancelled = false;
    setLoading(true);
    setError(null);
    fetch(`${API_BASE}${current.path}`)
      .then((res) => {
        if (!res.ok) throw new Error(res.statusText);
        return res.json();
      })
      .then((arr) => {
        if (!cancelled) setData(Array.isArray(arr) ? arr : []);
      })
      .catch((e) => {
        if (!cancelled) setError(e.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => { cancelled = true; };
  }, [active, current]);

  return (
    <div>
      <h1>Reference Data</h1>
      <p className="muted">Countries, grades, Umoja classes, and other lookup data.</p>

      <div className="ref-tabs">
        {ENDPOINTS.map((e) => (
          <button
            key={e.key}
            type="button"
            className={active === e.key ? 'active' : ''}
            onClick={() => setActive(e.key)}
          >
            {e.label}
          </button>
        ))}
      </div>

      <div className="card table-card">
        {error && <p className="error">Error: {error}</p>}
        {loading && <p className="muted">Loading…</p>}
        {!loading && !error && data.length === 0 && (
          <p className="muted">No records. Run the DDL and seed scripts first.</p>
        )}
        {!loading && !error && data.length > 0 && (
          <table className="data-table">
            <thead>
              <tr>
                {Object.keys(data[0]).filter((k) => typeof data[0][k] !== 'object').map((k) => (
                  <th key={k}>{k.replace(/_/g, ' ')}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {data.map((row, i) => (
                <tr key={row.id ?? i}>
                  {Object.entries(row).filter(([, v]) => typeof v !== 'object').map(([k, v]) => (
                    <td key={k}>{v == null ? '—' : String(v)}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
