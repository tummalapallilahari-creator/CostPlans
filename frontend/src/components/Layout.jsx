import { Outlet } from 'react-router-dom';
import { NavLink } from 'react-router-dom';
import './Layout.css';

export default function Layout({ children }) {
  return (
    <div className="layout">
      <header className="layout-header">
        <div className="layout-brand">Cost Plans System</div>
        <nav className="layout-nav">
          <NavLink to="/" className={({ isActive }) => (isActive ? 'active' : '')} end>
            Dashboard
          </NavLink>
          <NavLink to="/planning-years" className={({ isActive }) => (isActive ? 'active' : '')}>
            Planning Years
          </NavLink>
          <NavLink to="/reference" className={({ isActive }) => (isActive ? 'active' : '')}>
            Reference Data
          </NavLink>
        </nav>
      </header>
      <main className="layout-main">
        {children || <Outlet />}
      </main>
    </div>
  );
}
