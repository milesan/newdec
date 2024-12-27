import React, { useState } from 'react';
import { X } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface InventoryModalProps {
  accommodation: {
    id: string;
    title: string;
    inventory_count: number;
  };
  onClose: () => void;
  onSave: () => void;
}

export function InventoryModal({ accommodation, onClose, onSave }: InventoryModalProps) {
  const [inventoryCount, setInventoryCount] = useState<number>(accommodation.inventory_count || 1);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSave = async () => {
    if (inventoryCount < 1) {
      setError('Inventory count must be at least 1');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const { error: updateError } = await supabase
        .from('accommodations')
        .update({ 
          inventory_count: inventoryCount 
        })
        .eq('id', accommodation.id);

      if (updateError) throw updateError;

      onSave();
      onClose();
    } catch (e) {
      console.error('Error updating inventory:', e);
      setError(e instanceof Error ? e.message : 'Failed to update inventory');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-md w-full p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Update Inventory</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label htmlFor="inventory" className="block text-sm font-medium text-gray-700 mb-1">
              {accommodation.title}
            </label>
            <input
              id="inventory"
              type="number"
              min="1"
              value={inventoryCount}
              onChange={(e) => {
                const value = parseInt(e.target.value);
                setInventoryCount(isNaN(value) ? 1 : Math.max(1, value));
              }}
              className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
            />
            <p className="mt-1 text-sm text-gray-500">
              Minimum inventory count is 1
            </p>
          </div>

          {error && (
            <div className="text-red-500 text-sm bg-red-50 p-2 rounded">
              {error}
            </div>
          )}

          <div className="flex justify-end gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-600 hover:text-gray-800"
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={saving || inventoryCount < 1}
              className="bg-red-500 text-white px-4 py-2 rounded-lg hover:bg-red-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              {saving ? 'Saving...' : 'Save'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}