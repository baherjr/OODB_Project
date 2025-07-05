import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

const Sales = () => {
  const [sales, setSales] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const role = localStorage.getItem('role');
    if (role !== 'admin') {
      alert('Access denied. Only admins can view sales.');
      navigate('/'); // Redirect to home or another page
      return;
    }

    const fetchSales = async () => {
      try {
        const response = await fetch('http://localhost:3000/api/sales');
        if (!response.ok) {
          throw new Error('Failed to fetch sales');
        }
        const data = await response.json();
        setSales(data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchSales();
  }, [navigate]);

  if (loading) {
    return <div>Loading...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Sales</h1>
      <table className="table-auto w-full border-collapse border border-gray-300">
        <thead>
          <tr>
            <th className="border border-gray-300 px-4 py-2">Sale ID</th>
            <th className="border border-gray-300 px-4 py-2">Vehicle ID</th>
            <th className="border border-gray-300 px-4 py-2">Customer ID</th>
            <th className="border border-gray-300 px-4 py-2">Sale Date</th>
            <th className="border border-gray-300 px-4 py-2">Sale Price</th>
            <th className="border border-gray-300 px-4 py-2">Payment Method</th>
            <th className="border border-gray-300 px-4 py-2">Finance Term</th>
            <th className="border border-gray-300 px-4 py-2">Notes</th>
          </tr>
        </thead>
        <tbody>
          {sales.map((sale) => (
            <tr key={sale.sale_id}>
              <td className="border border-gray-300 px-4 py-2">{sale.sale_id}</td>
              <td className="border border-gray-300 px-4 py-2">{sale.vehicle_id}</td>
              <td className="border border-gray-300 px-4 py-2">{sale.customer_id}</td>
              <td className="border border-gray-300 px-4 py-2">{sale.sale_date}</td>
              <td className="border border-gray-300 px-4 py-2">${sale.sale_price}</td>
              <td className="border border-gray-300 px-4 py-2">{sale.payment_method}</td>
              <td className="border border-gray-300 px-4 py-2">{sale.finance_term || 'N/A'}</td>
              <td className="border border-gray-300 px-4 py-2">{sale.notes || 'N/A'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default Sales;