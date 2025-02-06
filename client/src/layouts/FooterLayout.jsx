import { Outlet } from 'react-router-dom';

export const FooterLayout = () => {
  return (
    <>
      <Outlet />
      {/* Este footer debería ser un componente para que sea reutilizable */}
      <footer>Este es el footer y debería ser un componente</footer>
    </>
  );
};
