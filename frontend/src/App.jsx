import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Nav from './components/nav';
import Login from './pages/login';
import Register from './pages/register';
import Vehicles from './pages/vehicles';
import Profile from './pages/profile';
import Sales from './pages/sales';

function App() {
  return (
    <Router>
      <Nav />
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/profile" element={<Profile />} />
        <Route path="/" element={<Vehicles />} />
        <Route path="/sales" element={<Sales />} /> {/* Add Sales route */}

        {/* Add other routes here */}
      </Routes>
    </Router>
  );
}

export default App;