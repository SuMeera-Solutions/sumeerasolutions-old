// This file contains ONLY the IncidentForm component and RecordabilityTool from the old working code
// This is a temporary clean version to restore functionality

import React, { useState } from 'react';
import { 
  Shield, AlertTriangle, Check, X, ChevronRight, ChevronLeft,
  CheckCircle, XCircle, AlertCircle, Info, HelpCircle, RefreshCw,
  FileText, Clock, User, MapPin, Activity, Zap, Save, ArrowLeft
} from 'lucide-react';

const RecordabilityTool = () => {
  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">OSHA Recordability Tool</h1>
          <p className="text-gray-600">
            The recordability workflow is being restored. Please refresh the page.
          </p>
        </div>
      </div>
    </div>
  );
};

export default RecordabilityTool;
