import { Link } from 'react-router-dom';

export const Page404 = () => {
  return (
    <>
      <main>
        <div>
          <h2>¡Oh, no! Parece que te perdiste.</h2>
          <div>
            Parece que estás buscando algo que no existe. ¿Quizás te equivocaste
            de URL? O tal vez la página que buscas se ha trasladado o eliminado.
          </div>

          <div>
            <Link to="/">
              <button>Volver al inicio</button>
            </Link>
          </div>
        </div>
      </main>
    </>
  );
};
