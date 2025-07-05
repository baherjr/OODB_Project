import React from 'react';
import { useNavigate } from 'react-router-dom';

const Nav = () => {
  const navigate = useNavigate();
  const isLoggedIn = !!localStorage.getItem('token');
  const role = localStorage.getItem('role'); // Get the role from localStorage

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('role'); // Remove role on logout
    navigate('/login');
  };

  return (
    <nav className="bg-blue-600 p-4 flex justify-between items-center">
      <h1 className="text-white text-2xl font-bold">CAR INVENTORY</h1>
      <div>
        {isLoggedIn ? (
          <>
            {role === 'admin' && (
              <button
                className="bg-white text-blue-600 px-4 py-2 rounded mr-2"
                onClick={() => navigate('/sales')}
              >
                Sales
              </button>
            )}
            <button
              className="bg-white text-blue-600 px-4 py-2 rounded mr-2"
              onClick={() => navigate('/profile')}
            >
              Profile
            </button>
            <button
              className="bg-white text-blue-600 px-4 py-2 rounded"
              onClick={handleLogout}
            >
              Logout
            </button>
          </>
        ) : (
          <>
            <button
              className="bg-white text-blue-600 px-4 py-2 rounded mr-2"
              onClick={() => navigate('/login')}
            >
              Login
            </button>
            <button
              className="bg-white text-blue-600 px-4 py-2 rounded"
              onClick={() => navigate('/register')}
            >
              Register
            </button>
          </>
        )}
      </div>
    </nav>
  );
};

export default Nav;