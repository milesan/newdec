import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Wifi, Zap, BedDouble, WifiOff, ZapOff, Bath } from 'lucide-react';
import clsx from 'clsx';
import type { Accommodation } from '../types';
import { getSeasonalDiscount } from '../utils/pricing';
import { useWeeklyAccommodations } from '../hooks/useWeeklyAccommodations';

interface Props {
  accommodations: Accommodation[];
  selectedAccommodation: string | null;
  onSelectAccommodation: (id: string) => void;
  selectedWeeks: Date[];
  currentMonth: Date;
}

const BED_SIZES = {
  '6-Bed Dorm': '90×200cm (35×79") - Single',
  '3-Bed Dorm': '90×200cm (35×79") - Single',
  'A-Frame Pod': '140×200cm (55×79") - Double',
  'Microcabin Left': '140×200cm (55×79") - Double',
  'Microcabin Middle': '140×200cm (55×79") - Double',
  'Microcabin Right': '140×200cm (55×79") - Double',
  'Writer\'s Room': '135×200cm (53×79") - Double',
  'Valleyview Room': '160×200cm (63×79") - Queen',
  'The Hearth': '180×200cm (71×79") - King',
  'Master\'s Suite': '160×200cm (63×79") - Queen',
  '2.2 Meter Tipi': '90×200cm (35×79") - Single',
  '4 Meter Bell Tent': '140×200cm (55×79") - Double',
  '5m Bell Tent': '160×200cm (63×79") - Queen',
  'Your Own Tent': 'Bring your own',
  'Van Parking': 'Bring your own',
  'I\'m staying with someone else / +1': 'N/A'
} as const;

const HAS_ELECTRICITY = [
  'Microcabin Left',
  'Microcabin Middle',
  'Microcabin Right',
  '6-Bed Dorm',
  '3-Bed Dorm',
  'Writer\'s Room',
  'Valleyview Room',
  'The Hearth',
  'Master\'s Suite'
];

const HAS_WIFI = [
  'Writer\'s Room',
  'The Hearth',
  'Valleyview Room',
  'Master\'s Suite'
];

export function CabinSelector({
  accommodations,
  selectedAccommodation,
  onSelectAccommodation,
  selectedWeeks,
  currentMonth
}: Props) {
  const { checkAvailability, getMaxOccupancy, isAccommodationAvailable } = useWeeklyAccommodations();
  const [availabilityStatus, setAvailabilityStatus] = useState<Record<string, boolean>>({});
  
  const hasWifi = (title: string) => HAS_WIFI.includes(title);
  const hasElectricity = (title: string) => HAS_ELECTRICITY.includes(title);

  useEffect(() => {
    if (selectedWeeks.length > 0) {
      const startDate = selectedWeeks[0];
      const endDate = selectedWeeks[selectedWeeks.length - 1];
      checkAvailability(startDate, endDate);
      updateAvailabilityStatus(startDate, endDate);
    }
  }, [selectedWeeks, checkAvailability]);

  const updateAvailabilityStatus = async (startDate: Date, endDate: Date) => {
    const status: Record<string, boolean> = {};
    
    for (const acc of accommodations) {
      if (!acc.parent_accommodation_id) { // Only check parent accommodations
        status[acc.id] = await isAccommodationAvailable(acc, startDate, endDate);
      }
    }
    
    setAvailabilityStatus(status);
  };

  // Filter accommodations based on season and type
  const visibleAccommodations = accommodations.filter(acc => {
    // Filter out individual bed entries
    if (acc.parent_accommodation_id) return false;

    // Check if it's tent season (April 15 - September 1)
    const currentDate = selectedWeeks.length > 0 ? selectedWeeks[0] : new Date();
    const month = currentDate.getMonth();
    const day = currentDate.getDate();
    const isTentSeason = (month > 3 || (month === 3 && day >= 15)) && 
                        (month < 8 || (month === 8 && day <= 1));

    // Hide tents outside of season
    if (!isTentSeason && (acc.type === 'Bell Tent' || acc.type === 'Tipi' || acc.title === 'Your Own Tent')) {
      return false;
    }

    return true;
  }).sort((a, b) => {
    // Sort free accommodations last
    if (a.price === 0 && b.price !== 0) return 1;
    if (a.price !== 0 && b.price === 0) return -1;
    return 0;
  });

  return (
    <div className="mt-0">
      <h2 className="text-2xl font-serif font-light text-stone-900 mb-6 text-center">
        Select Your Accommodation
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {visibleAccommodations.map((accommodation) => {
          const seasonalDiscount = selectedWeeks.length > 0 ? 
            selectedWeeks.reduce((acc, week) => acc + getSeasonalDiscount(week), 0) / selectedWeeks.length : 
            0;
          
          const hasDiscount = seasonalDiscount > 0;
          const discountedPrice = Math.round(accommodation.price * (1 - seasonalDiscount));
          
          let availableBeds = accommodation.inventory_count;
          if (accommodation.is_fungible && !accommodation.is_unlimited && selectedWeeks.length > 0) {
            const maxOccupancy = getMaxOccupancy(
              accommodation.id, 
              selectedWeeks[0], 
              selectedWeeks[selectedWeeks.length - 1]
            );
            availableBeds = accommodation.inventory_count - maxOccupancy;
          }

          const isAvailable = selectedWeeks.length === 0 ? false : 
            availabilityStatus[accommodation.id] ?? true;
          
          return (
            <motion.button
              key={accommodation.id}
              onClick={() => isAvailable && onSelectAccommodation(accommodation.id)}
              className={clsx(
                'relative overflow-hidden transition-all duration-300',
                selectedAccommodation === accommodation.id 
                  ? 'border-2 border-emerald-600 shadow-lg transform -translate-y-1' 
                  : 'border-2 border-stone-200 hover:border-emerald-600/20',
                accommodation.price === 0 && 'md:col-span-1 lg:col-span-1',
                !isAvailable && selectedWeeks.length > 0 && 'opacity-50 cursor-not-allowed',
                selectedWeeks.length === 0 && 'opacity-50 cursor-not-allowed'
              )}
              whileHover={isAvailable ? { scale: 1.02 } : undefined}
              whileTap={isAvailable ? { scale: 0.98 } : undefined}
            >
              <div className="aspect-[4/3] relative">
                <img
                  src={accommodation.image_url}
                  alt={accommodation.title}
                  className={clsx(
                    "absolute inset-0 w-full h-full object-cover",
                    !isAvailable && selectedWeeks.length > 0 && "grayscale"
                  )}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
                
                {/* Show bed count only for dorms */}
                {accommodation.type.includes('Dorm') && selectedWeeks.length > 0 && (
                  <div className="absolute top-4 left-4 bg-black/80 text-white px-3 py-1 rounded-full text-sm">
                    {availableBeds} {availableBeds === 1 ? 'bed' : 'beds'} available
                  </div>
                )}

                {/* Utilities Icons */}
                <div className="absolute top-4 right-4 flex gap-2">
                  {hasWifi(accommodation.title) ? (
                    <div className="group relative">
                      <Wifi className="w-5 h-5 text-white" />
                      <div className="absolute right-0 top-full mt-2 w-48 p-2 bg-black/90 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                        Dedicated 1000Mbps internet connection shared between seven guest house rooms
                      </div>
                    </div>
                  ) : (
                    <div className="group relative">
                      <WifiOff className="w-5 h-5 text-white/70" />
                      <div className="absolute right-0 top-full mt-2 w-32 p-2 bg-black/90 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                        No WiFi available
                        {accommodation.title === 'A-Frame Pod' && (
                          <span className="block mt-1">Cabin being built nearby</span>
                        )}
                      </div>
                    </div>
                  )}
                  
                  {hasElectricity(accommodation.title) ? (
                    <div className="group relative">
                      <Zap className="w-5 h-5 text-white" />
                      <div className="absolute right-0 top-full mt-2 w-48 p-2 bg-black/90 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                        Electrical outlets available
                      </div>
                    </div>
                  ) : (
                    <div className="group relative">
                      <ZapOff className="w-5 h-5 text-white/70" />
                      <div className="absolute right-0 top-full mt-2 w-32 p-2 bg-black/90 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                        No electricity
                      </div>
                    </div>
                  )}
                  
                  <div className="group relative">
                    <BedDouble className="w-5 h-5 text-white" />
                    <div className="absolute right-0 top-full mt-2 w-48 p-2 bg-black/90 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                      {BED_SIZES[accommodation.title as keyof typeof BED_SIZES]}
                    </div>
                  </div>

                  {accommodation.title === 'Master\'s Suite' && (
                    <div className="group relative">
                      <Bath className="w-5 h-5 text-white" />
                      <div className="absolute right-0 top-full mt-2 w-48 p-2 bg-black/90 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                        Ensuite bathroom (needs remodeling, price adjusted)
                      </div>
                    </div>
                  )}
                </div>

                {selectedWeeks.length === 0 ? (
                  <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                    <p className="text-white font-display text-xl">Select Dates</p>
                  </div>
                ) : !isAvailable && (
                  <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                    <p className="text-white font-display text-xl">Not Available</p>
                  </div>
                )}
              </div>
              <div className="p-4 bg-white">
                <h3 className="text-xl font-serif">{accommodation.title}</h3>
                <div className="mt-2">
                  {accommodation.price === 0 ? (
                    <p className="text-emerald-700 font-medium">Free</p>
                  ) : hasDiscount ? (
                    <>
                      <p className="text-emerald-700 font-medium">
                        €{discountedPrice}/week
                        <span className="text-stone-400 text-sm ml-2">❧</span>
                        <span className="text-stone-400 line-through text-sm ml-2">
                          €{accommodation.price}
                        </span>
                      </p>
                      <p className="text-sm text-emerald-600 mt-1">
                        Slower season rate
                      </p>
                    </>
                  ) : (
                    <p className="text-stone-600">€{accommodation.price} per week</p>
                  )}
                </div>
              </div>
            </motion.button>
          );
        })}
      </div>
    </div>
  );
}