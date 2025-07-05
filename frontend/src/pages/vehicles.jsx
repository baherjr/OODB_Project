import React, { useEffect, useState } from 'react';

const Vehicles = () => {
  const [vehicles, setVehicles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filter, setFilter] = useState('All'); // Default filter
  const [role, setRole] = useState(localStorage.getItem('role')); // Get role from localStorage
  const [showOrderModal, setShowOrderModal] = useState(false); // Modal visibility for ordering
  const [selectedVehicle, setSelectedVehicle] = useState(null); // Selected vehicle for ordering
  const [paymentMethod, setPaymentMethod] = useState('cash'); // Default payment method
  const [financeTerm, setFinanceTerm] = useState(''); // Finance term input
  const [note, setNote] = useState(''); // Note for the order
  const [showEditModal, setShowEditModal] = useState(false); // Modal visibility for editing
  const [editVehicle, setEditVehicle] = useState(null); // Vehicle being edited
  const [showAddModal, setShowAddModal] = useState(false); // Modal visibility for adding
  const [newVehicle, setNewVehicle] = useState({
    make: '',
    model: '',
    year: '',
    vin: '',
    purchase_price: '',
    price: '',
    date_acquired: '',
    status: 'in_stock',
  }); // New vehicle data

  useEffect(() => {
    const fetchVehicles = async () => {
      setVehicles([]); // Clear previous state
      setLoading(true); // Set loading to true before fetching
      try {
        const response = await fetch(`http://localhost:3000/api/vehicles?status=${filter}`);
        if (!response.ok) {
          throw new Error('Failed to fetch vehicles');
        }
        const data = await response.json();
        setVehicles(data); // Update state with new data
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchVehicles();
  }, [filter]); // Refetch data when filter changes

  const handleFilterChange = (status) => {
    setFilter(status); // Update filter state
  };

  const handleOrderClick = (vehicle) => {
    setSelectedVehicle(vehicle); // Set the selected vehicle
    setShowOrderModal(true); // Show the order modal
  };

  const handleOrderSubmit = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      alert('You must be logged in to place an order.');
      return;
    }

    // Decode the token to get the customer_id
    const payload = JSON.parse(atob(token.split('.')[1]));
    const customerId = payload.customer_id;

    const saleData = {
      vehicle_id: selectedVehicle.vehicle_id,
      customer_id: customerId,
      sale_date: new Date().toISOString().split('T')[0], // Current date
      sale_price: selectedVehicle.price, // Use the price from the vehicle data
      payment_method: paymentMethod, // Selected payment method
      finance_term: paymentMethod === 'finance' ? financeTerm : null, // Finance term only if payment method is finance
      notes: note, // User-provided note
    };

    try {
      const response = await fetch('http://localhost:3000/api/sales/add', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(saleData),
      });

      if (response.ok) {
        alert('Order placed successfully!');
        setShowOrderModal(false); // Close the modal
        setFilter('in_stock'); // Refresh the list of in-stock vehicles
      } else {
        const errorData = await response.json();
        alert(`Failed to place order: ${errorData.error}`);
      }
    } catch (err) {
      console.error(err);
      alert('An error occurred while placing the order.');
    }
  };

  const handleDelete = async (vehicleId) => {
    try {
      const response = await fetch(`http://localhost:3000/api/vehicles/delete/${vehicleId}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        alert('Vehicle deleted successfully!');
        setVehicles(vehicles.filter((vehicle) => vehicle.vehicle_id !== vehicleId)); // Remove from UI
      } else {
        const errorData = await response.json();
        alert(`Failed to delete vehicle: ${errorData.error}`);
      }
    } catch (err) {
      console.error(err);
      alert('An error occurred while deleting the vehicle.');
    }
  };

  const handleEditClick = async (vehicleId) => {
    try {
      const response = await fetch(`http://localhost:3000/api/vehicles/${vehicleId}`);
      if (!response.ok) {
        throw new Error('Failed to fetch vehicle data');
      }
      const data = await response.json();
      setEditVehicle(data); // Set the vehicle data for editing
      setShowEditModal(true); // Show the edit modal
    } catch (err) {
      console.error(err);
      alert('An error occurred while fetching the vehicle data.');
    }
  };

  const handleEditSubmit = async () => {
    try {
      const response = await fetch(`http://localhost:3000/api/vehicles/edit/${editVehicle.vehicle_id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(editVehicle),
      });

      if (response.ok) {
        alert('Vehicle updated successfully!');
        setShowEditModal(false); // Close the modal
        setFilter('All'); // Refresh the list of vehicles
      } else {
        const errorData = await response.json();
        alert(`Failed to update vehicle: ${errorData.error}`);
      }
    } catch (err) {
      console.error(err);
      alert('An error occurred while updating the vehicle.');
    }
  };

  const handleAddSubmit = async () => {
    try {
      const response = await fetch('http://localhost:3000/api/vehicles/add', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(newVehicle),
      });

      if (response.ok) {
        const data = await response.json();
        alert(`Vehicle added successfully with ID: ${data.vehicle_id}`);
        setShowAddModal(false); // Close the modal
        setFilter('All'); // Refresh the list of vehicles
      } else {
        const errorData = await response.json();
        alert(`Failed to add vehicle: ${errorData.error}`);
      }
    } catch (err) {
      console.error(err);
      alert('An error occurred while adding the vehicle.');
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Vehicles</h1>

      {/* Add Vehicle Button */}
      {role === 'admin' && (
        <button
          className="bg-green-600 text-white px-4 py-2 rounded mb-4"
          onClick={() => setShowAddModal(true)}
        >
          Add Vehicle
        </button>
      )}

      {/* Filter Buttons */}
      <div className="mb-4">
        <button
          className={`px-4 py-2 mr-2 rounded ${filter === 'All' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
          onClick={() => handleFilterChange('All')}
        >
          All
        </button>
        <button
          className={`px-4 py-2 mr-2 rounded ${filter === 'in_stock' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
          onClick={() => handleFilterChange('in_stock')}
        >
          In Stock
        </button>
        <button
          className={`px-4 py-2 mr-2 rounded ${filter === 'sold' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
          onClick={() => handleFilterChange('sold')}
        >
          Sold
        </button>
        <button
          className={`px-4 py-2 rounded ${filter === 'maintenance' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
          onClick={() => handleFilterChange('maintenance')}
        >
          Maintenance
        </button>
      </div>

      {/* Vehicles Table */}
      <table className="table-auto w-full border-collapse border border-gray-300">
        <thead>
          <tr>
            <th className="border border-gray-300 px-4 py-2">Vehicle ID</th>
            <th className="border border-gray-300 px-4 py-2">Make</th>
            <th className="border border-gray-300 px-4 py-2">Model</th>
            <th className="border border-gray-300 px-4 py-2">Year</th>
            <th className="border border-gray-300 px-4 py-2">VIN</th>
            <th className="border border-gray-300 px-4 py-2">Price</th>
            <th className="border border-gray-300 px-4 py-2">Status</th>
            <th className="border border-gray-300 px-4 py-2">Actions</th>
          </tr>
        </thead>
        <tbody>
          {vehicles.map((vehicle) => (
            <tr key={vehicle.vehicle_id}>
              <td className="border border-gray-300 px-4 py-2">{vehicle.vehicle_id}</td>
              <td className="border border-gray-300 px-4 py-2">{vehicle.make}</td>
              <td className="border border-gray-300 px-4 py-2">{vehicle.model}</td>
              <td className="border border-gray-300 px-4 py-2">{vehicle.year}</td>
              <td className="border border-gray-300 px-4 py-2">{vehicle.vin}</td>
              <td className="border border-gray-300 px-4 py-2">{vehicle.price}</td>
              <td className="border border-gray-300 px-4 py-2">{vehicle.status}</td>
              <td className="border border-gray-300 px-4 py-2">
                {role === 'admin' ? (
                  <>
                    <button
                      className="bg-yellow-500 text-white px-4 py-2 rounded mr-2"
                      onClick={() => handleEditClick(vehicle.vehicle_id)}
                    >
                      Edit
                    </button>
                    <button
                      className="bg-red-600 text-white px-4 py-2 rounded"
                      onClick={() => handleDelete(vehicle.vehicle_id)}
                    >
                      Delete
                    </button>
                  </>
                ) : (
                  vehicle.status === 'in_stock' && (
                    <button
                      className="bg-green-600 text-white px-4 py-2 rounded"
                      onClick={() => handleOrderClick(vehicle)}
                    >
                      Order
                    </button>
                  )
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* Order Modal */}
      {showOrderModal && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
          <div className="bg-white p-6 rounded shadow-md">
            <h2 className="text-xl font-bold mb-4">Place Order</h2>
            <p className="mb-4">Vehicle: {selectedVehicle.make} {selectedVehicle.model}</p>
            <p className="mb-4">Price: ${selectedVehicle.price}</p>
            <label className="block mb-2">Payment Method:</label>
            <select
              className="block w-full p-2 mb-4 border rounded"
              value={paymentMethod}
              onChange={(e) => setPaymentMethod(e.target.value)}
            >
              <option value="cash">Cash</option>
              <option value="credit">Credit</option>
              <option value="finance">Finance</option>
            </select>
            {paymentMethod === 'finance' && (
              <div className="mb-4">
                <label className="block mb-2">Finance Term (in months):</label>
                <input
                  type="number"
                  className="block w-full p-2 border rounded"
                  value={financeTerm}
                  onChange={(e) => setFinanceTerm(e.target.value)}
                  placeholder="Enter finance term"
                />
              </div>
            )}
            <label className="block mb-2">Note:</label>
            <textarea
              className="block w-full p-2 mb-4 border rounded"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Add a note (optional)"
            />
            <div className="flex justify-end">
              <button
                className="bg-gray-300 text-black px-4 py-2 rounded mr-2"
                onClick={() => setShowOrderModal(false)}
              >
                Cancel
              </button>
              <button
                className="bg-blue-600 text-white px-4 py-2 rounded"
                onClick={handleOrderSubmit}
              >
                Confirm Order
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Modal */}
      {showEditModal && editVehicle && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
          <div className="bg-white p-6 rounded shadow-md">
            <h2 className="text-xl font-bold mb-4">Edit Vehicle</h2>
            <label className="block mb-2">Make:</label>
            <input
              type="text"
              className="block w-full p-2 mb-4 border rounded"
              value={editVehicle.make}
              onChange={(e) => setEditVehicle({ ...editVehicle, make: e.target.value })}
            />
            <label className="block mb-2">Model:</label>
            <input
              type="text"
              className="block w-full p-2 mb-4 border rounded"
              value={editVehicle.model}
              onChange={(e) => setEditVehicle({ ...editVehicle, model: e.target.value })}
            />
            <label className="block mb-2">Year:</label>
            <input
              type="number"
              className="block w-full p-2 mb-4 border rounded"
              value={editVehicle.year}
              onChange={(e) => setEditVehicle({ ...editVehicle, year: e.target.value })}
            />
            <label className="block mb-2">Price:</label>
            <input
              type="number"
              className="block w-full p-2 mb-4 border rounded"
              value={editVehicle.price}
              onChange={(e) => setEditVehicle({ ...editVehicle, price: e.target.value })}
            />
            <label className="block mb-2">Status:</label>
            <select
              className="block w-full p-2 mb-4 border rounded"
              value={editVehicle.status}
              onChange={(e) => setEditVehicle({ ...editVehicle, status: e.target.value })}
            >
              <option value="in_stock">In Stock</option>
              <option value="sold">Sold</option>
              <option value="maintenance">Maintenance</option>
            </select>
            <div className="flex justify-end">
              <button
                className="bg-gray-300 text-black px-4 py-2 rounded mr-2"
                onClick={() => setShowEditModal(false)}
              >
                Cancel
              </button>
              <button
                className="bg-blue-600 text-white px-4 py-2 rounded"
                onClick={handleEditSubmit}
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Vehicle Modal */}
      {showAddModal && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
          <div className="bg-white p-6 rounded shadow-md">
            <h2 className="text-xl font-bold mb-4">Add Vehicle</h2>
            <label className="block mb-2">Make:</label>
            <input
              type="text"
              className="block w-full p-2 mb-4 border rounded"
              value={newVehicle.make}
              onChange={(e) => setNewVehicle({ ...newVehicle, make: e.target.value })}
            />
            <label className="block mb-2">Model:</label>
            <input
              type="text"
              className="block w-full p-2 mb-4 border rounded"
              value={newVehicle.model}
              onChange={(e) => setNewVehicle({ ...newVehicle, model: e.target.value })}
            />
            <label className="block mb-2">Year:</label>
            <input
              type="number"
              className="block w-full p-2 mb-4 border rounded"
              value={newVehicle.year}
              onChange={(e) => setNewVehicle({ ...newVehicle, year: e.target.value })}
            />
            <label className="block mb-2">VIN:</label>
            <input
              type="text"
              className="block w-full p-2 mb-4 border rounded"
              value={newVehicle.vin}
              onChange={(e) => setNewVehicle({ ...newVehicle, vin: e.target.value })}
            />
            <label className="block mb-2">Purchase Price:</label>
            <input
              type="number"
              className="block w-full p-2 mb-4 border rounded"
              value={newVehicle.purchase_price}
              onChange={(e) => setNewVehicle({ ...newVehicle, purchase_price: e.target.value })}
            />
            <label className="block mb-2">Price:</label>
            <input
              type="number"
              className="block w-full p-2 mb-4 border rounded"
              value={newVehicle.price}
              onChange={(e) => setNewVehicle({ ...newVehicle, price: e.target.value })}
            />
            <label className="block mb-2">Date Acquired:</label>
            <input
              type="date"
              className="block w-full p-2 mb-4 border rounded"
              value={newVehicle.date_acquired}
              onChange={(e) => setNewVehicle({ ...newVehicle, date_acquired: e.target.value })}
            />
            <label className="block mb-2">Status:</label>
            <select
              className="block w-full p-2 mb-4 border rounded"
              value={newVehicle.status}
              onChange={(e) => setNewVehicle({ ...newVehicle, status: e.target.value })}
            >
              <option value="in_stock">In Stock</option>
              <option value="sold">Sold</option>
              <option value="maintenance">Maintenance</option>
            </select>
            <div className="flex justify-end">
              <button
                className="bg-gray-300 text-black px-4 py-2 rounded mr-2"
                onClick={() => setShowAddModal(false)}
              >
                Cancel
              </button>
              <button
                className="bg-blue-600 text-white px-4 py-2 rounded"
                onClick={handleAddSubmit}
              >
                Add Vehicle
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Vehicles;