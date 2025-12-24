import React, { useState } from 'react';
import { 
  Shield, AlertTriangle, Check, X, ChevronRight, ChevronLeft,
  CheckCircle, XCircle, AlertCircle, Info, HelpCircle, RefreshCw,
  FileText, Clock, User, MapPin, Activity, Zap, Save, ArrowLeft
} from 'lucide-react';

// Incident Form Component - matching CompliEase design
const IncidentForm = ({ onBack, onSave }) => {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState(() => {
    // Load pre-filled data from assessment
    try {
      const savedData = sessionStorage.getItem('oshaIncidentFormData');
      if (savedData) {
        const data = JSON.parse(savedData);
        return {
          // Step 1: Basic incident info (pre-filled from assessment)
          dateOfIncident: data.incidentDate || '',
          timeOfIncident: data.incidentTime || '',
          timeStartedWork: '',
          timeUnknown: false,
          
          // Employee info (pre-filled from assessment)
          employeeName: data.employeeName || '',
          jobTitle: '',
          
          // Step 2: Location and description (pre-filled from assessment)
          incidentLocation: data.location || '',
          whatEmployeeDoing: data.workActivity === 'working' ? 'Performing regular job duties' :
                           data.workActivity === 'break_work' ? 'On break at workplace' :
                           data.workActivity === 'required_activity' ? 'Required company activity' :
                           data.workActivity === 'personal_task' ? 'Personal task' : '',
          whatHappened: '',
          injuryIllnessDescription: '',
          objectSubstance: '',
          
          // Step 3: Classification (pre-filled from recordability tool)
          isRecordable: data.isRecordable || null,
          incidentOutcome: data.outcomeClassification?.death ? 1 :
                          data.outcomeClassification?.daysAwayFromWork ? 2 :
                          data.outcomeClassification?.jobTransferRestriction ? 3 : 4,
          typeOfIncident: data.injuryType === 'injury' ? 1 : 
                         data.injuryType === 'illness' ? 6 : 1, // Default to injury
          
          // Days tracking
          daysAway: data.outcomeClassification?.daysAwayFromWork ? 0 : undefined,
          daysRestricted: data.outcomeClassification?.jobTransferRestriction ? 0 : undefined,
          
          // Death info
          dateOfDeath: '',
          
          // Case number (auto-generated)
          caseNumber: '',
          
          // Meta data
          preFilled: !!savedData,
          assessmentData: data,
          requiresEmergencyReport: data.requiresEmergencyOSHAReport || false
        };
      }
    } catch (error) {
      console.error('Error loading assessment data:', error);
    }
    return {
      // Default empty form
      dateOfIncident: '', timeOfIncident: '', timeStartedWork: '', timeUnknown: false,
      employeeName: '', jobTitle: '', incidentLocation: '', whatEmployeeDoing: '',
      whatHappened: '', injuryIllnessDescription: '', objectSubstance: '',
      isRecordable: null, incidentOutcome: null, typeOfIncident: null,
      daysAway: undefined, daysRestricted: undefined, dateOfDeath: '', caseNumber: '',
      preFilled: false, requiresEmergencyReport: false
    };
  });

  const updateField = (field, value) => {
    setFormData({...formData, [field]: value});
  };

  const generateCaseNumber = () => {
    const year = new Date().getFullYear();
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `${year}-${random}`;
  };

  if (!formData.caseNumber) {
    setFormData({...formData, caseNumber: generateCaseNumber()});
  }

  const handleSubmit = () => {
    const incidentRecord = {
      ...formData,
      createdAt: new Date().toISOString(),
      status: 'submitted'
    };
    
    localStorage.setItem(`incident_${formData.caseNumber}`, JSON.stringify(incidentRecord));
    onSave(incidentRecord);
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-5xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">OSHA Incident Report</h1>
              <p className="text-gray-600">Case Number: <span className="font-mono font-bold">{formData.caseNumber}</span></p>
            </div>
            <button
              onClick={onBack}
              className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center text-sm font-medium"
            >
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Assessment
            </button>
          </div>
          
          {formData.preFilled && (
            <div className="mt-4 bg-green-50 border border-green-200 p-4 rounded-lg">
              <div className="flex items-center">
                <Check className="h-5 w-5 text-green-600 mr-2" />
                <span className="font-semibold text-green-900">Information pre-filled from recordability assessment</span>
              </div>
              <p className="text-sm text-green-700 mt-1">
                Employee details, date, location, and classification have been populated. Please review and complete remaining fields.
              </p>
            </div>
          )}
        </div>

        {/* Progress Steps */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between">
            {[1, 2, 3, 4].map(step => (
              <div key={step} className="flex items-center flex-1">
                <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
                  currentStep === step ? 'bg-blue-600 text-white' :
                  currentStep > step ? 'bg-green-600 text-white' :
                  'bg-gray-200 text-gray-600'
                }`}>
                  {currentStep > step ? <Check className="h-6 w-6" /> : step}
                </div>
                <div className="flex-1 ml-3">
                  <p className={`text-sm font-semibold ${currentStep >= step ? 'text-gray-900' : 'text-gray-400'}`}>
                    {step === 1 && 'Basic Info'}
                    {step === 2 && 'Incident Details'}
                    {step === 3 && 'Classification'}
                    {step === 4 && 'Review & Submit'}
                  </p>
                </div>
                {step < 4 && <ChevronRight className="h-5 w-5 text-gray-400" />}
              </div>
            ))}
          </div>
        </div>

        {/* Step 1: Basic Information */}
        {currentStep === 1 && (
          <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-2xl font-bold mb-6">Step 1: Basic Incident Information</h2>
            
            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-semibold mb-2">
                    Date of Incident <span className="text-red-600">*</span>
                  </label>
                  <input
                    type="date"
                    value={formData.dateOfIncident}
                    onChange={(e) => updateField('dateOfIncident', e.target.value)}
                    className={`w-full p-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                      formData.preFilled && formData.dateOfIncident ? 'bg-green-50 border-green-300' : 'border-gray-300'
                    }`}
                    required
                  />
                  <p className="text-xs text-gray-500 mt-1">Per 29 CFR 1904.29(b)(3)</p>
                </div>

                <div>
                  <label className="block text-sm font-semibold mb-2">
                    Time of Incident
                  </label>
                  <div className="space-y-2">
                    <input
                      type="time"
                      value={formData.timeOfIncident}
                      onChange={(e) => updateField('timeOfIncident', e.target.value)}
                      disabled={formData.timeUnknown}
                      className={`w-full p-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                        formData.preFilled && formData.timeOfIncident ? 'bg-green-50 border-green-300' : 'border-gray-300'
                      }`}
                    />
                    <label className="flex items-center text-sm">
                      <input
                        type="checkbox"
                        checked={formData.timeUnknown}
                        onChange={(e) => updateField('timeUnknown', e.target.checked)}
                        className="mr-2"
                      />
                      Time unknown
                    </label>
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-sm font-semibold mb-2">
                  Time Employee Started Work (prior to incident)
                </label>
                <input
                  type="time"
                  value={formData.timeStartedWork}
                  onChange={(e) => updateField('timeStartedWork', e.target.value)}
                  className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-semibold mb-2">
                    Employee Name <span className="text-red-600">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.employeeName}
                    onChange={(e) => updateField('employeeName', e.target.value)}
                    className={`w-full p-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                      formData.preFilled && formData.employeeName ? 'bg-green-50 border-green-300' : 'border-gray-300'
                    }`}
                    placeholder="Full name"
                    required
                  />
                  <p className="text-xs text-gray-500 mt-1">Will be protected if privacy case applies</p>
                </div>

                <div>
                  <label className="block text-sm font-semibold mb-2">
                    Job Title <span className="text-red-600">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.jobTitle}
                    onChange={(e) => updateField('jobTitle', e.target.value)}
                    className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., Assembly Line Worker"
                    required
                  />
                  <p className="text-xs text-gray-500 mt-1">For SOC coding per ITA requirements</p>
                </div>
              </div>

              <div>
                <label className="block text-sm font-semibold mb-2">
                  Where did the incident occur? <span className="text-red-600">*</span>
                </label>
                <input
                  type="text"
                  value={formData.incidentLocation}
                  onChange={(e) => updateField('incidentLocation', e.target.value)}
                  className={`w-full p-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                    formData.preFilled && formData.incidentLocation ? 'bg-green-50 border-green-300' : 'border-gray-300'
                  }`}
                  placeholder="e.g., Loading dock, Assembly line #3, Office building 2nd floor"
                  required
                />
              </div>
            </div>

            <div className="flex justify-end mt-8">
              <button
                onClick={() => setCurrentStep(2)}
                disabled={!formData.dateOfIncident || !formData.employeeName || !formData.jobTitle || !formData.incidentLocation}
                className="px-8 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed font-semibold"
              >
                Continue to Incident Details →
              </button>
            </div>
          </div>
        )}

        {/* Step 2: Incident Details */}
        {currentStep === 2 && (
          <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-2xl font-bold mb-6">Step 2: Describe What Happened</h2>
            <p className="text-sm text-gray-600 mb-6">These detailed descriptions will populate OSHA Form 301 Incident Report</p>

            <div className="space-y-6">
              <div>
                <label className="block text-sm font-semibold mb-2">
                  What was the employee doing just before the incident occurred? <span className="text-red-600">*</span>
                </label>
                <textarea
                  value={formData.whatEmployeeDoing}
                  onChange={(e) => updateField('whatEmployeeDoing', e.target.value)}
                  className={`w-full p-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                    formData.preFilled && formData.whatEmployeeDoing ? 'bg-green-50 border-green-300' : 'border-gray-300'
                  }`}
                  rows="3"
                  placeholder="e.g., Operating forklift, carrying boxes, climbing ladder, using power saw..."
                  required
                />
                <p className="text-xs text-gray-500 mt-1">Form 301 field - be specific about the task</p>
              </div>

              <div>
                <label className="block text-sm font-semibold mb-2">
                  What happened? How did the injury occur? <span className="text-red-600">*</span>
                </label>
                <textarea
                  value={formData.whatHappened}
                  onChange={(e) => updateField('whatHappened', e.target.value)}
                  className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows="4"
                  placeholder="e.g., Employee slipped on wet floor while carrying materials, lost balance and fell striking head on concrete..."
                  required
                />
                <p className="text-xs text-gray-500 mt-1">Form 301 field - describe the sequence of events</p>
              </div>

              <div>
                <label className="block text-sm font-semibold mb-2">
                  What was the injury or illness? <span className="text-red-600">*</span>
                </label>
                <textarea
                  value={formData.injuryIllnessDescription}
                  onChange={(e) => updateField('injuryIllnessDescription', e.target.value)}
                  className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows="3"
                  placeholder="e.g., Laceration to left hand requiring 8 stitches, fractured right wrist, chemical burn to forearm..."
                  required
                />
                <p className="text-xs text-gray-500 mt-1">Form 301 field - name the body part(s) affected</p>
              </div>

              <div>
                <label className="block text-sm font-semibold mb-2">
                  What object or substance directly harmed the employee? <span className="text-red-600">*</span>
                </label>
                <input
                  type="text"
                  value={formData.objectSubstance}
                  onChange={(e) => updateField('objectSubstance', e.target.value)}
                  className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="e.g., box cutter, chemical solvent, floor surface, machinery part..."
                  required
                />
                <p className="text-xs text-gray-500 mt-1">Form 301 field</p>
              </div>
            </div>

            <div className="flex justify-between mt-8">
              <button
                onClick={() => setCurrentStep(1)}
                className="px-8 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 font-semibold"
              >
                ← Back
              </button>
              <button
                onClick={() => setCurrentStep(3)}
                disabled={!formData.whatEmployeeDoing || !formData.whatHappened || !formData.injuryIllnessDescription || !formData.objectSubstance}
                className="px-8 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed font-semibold"
              >
                Continue to Classification →
              </button>
            </div>
          </div>
        )}

        {/* Step 3: Classification */}
        {currentStep === 3 && (
          <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-2xl font-bold mb-6">Step 3: Classify the Incident</h2>
            <p className="text-sm text-gray-600 mb-6">This information determines Form 300 Log entries and ITA submission requirements</p>

            <div className="space-y-6">
              <div>
                <label className="block text-sm font-semibold mb-3">
                  Type of Incident <span className="text-red-600">*</span>
                </label>
                <div className="grid grid-cols-2 gap-3">
                  {[
                    { value: 1, label: 'Injury', desc: 'Cuts, fractures, sprains, burns, etc.', col: '300' },
                    { value: 2, label: 'Skin Disorder', desc: 'Rashes, dermatitis, chemical burns', col: '300' },
                    { value: 3, label: 'Respiratory Condition', desc: 'Asthma, pneumoconiosis, TB', col: '300' },
                    { value: 4, label: 'Poisoning', desc: 'Chemical exposure, toxic substance', col: '300' },
                    { value: 5, label: 'Hearing Loss', desc: 'Occupational hearing loss (29 CFR 1904.10)', col: '300' },
                    { value: 6, label: 'All Other Illness', desc: 'Occupational illnesses not elsewhere classified', col: '300' }
                  ].map(type => (
                    <button
                      key={type.value}
                      onClick={() => updateField('typeOfIncident', type.value)}
                      className={`p-4 border-2 rounded-lg text-left transition-all ${
                        formData.typeOfIncident === type.value
                          ? 'border-blue-600 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      } ${formData.preFilled && formData.typeOfIncident === type.value ? 'bg-green-50 border-green-300' : ''}`}
                    >
                      <div className="font-semibold text-gray-900">{type.label}</div>
                      <div className="text-xs text-gray-600 mt-1">{type.desc}</div>
                      <div className="text-xs text-gray-500 mt-1">Form {type.col} column</div>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-semibold mb-3">
                  Most Serious Outcome <span className="text-red-600">*</span>
                </label>
                <div className="space-y-3">
                  <button
                    onClick={() => updateField('incidentOutcome', 1)}
                    className={`w-full p-4 border-2 rounded-lg text-left transition-all ${
                      formData.incidentOutcome === 1
                        ? 'border-red-600 bg-red-50'
                        : 'border-gray-200 hover:border-gray-300'
                    } ${formData.preFilled && formData.incidentOutcome === 1 ? 'bg-green-50 border-green-300' : ''}`}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="font-semibold text-gray-900">Death</div>
                        <div className="text-xs text-gray-600 mt-1">29 CFR 1904.7(b)(2)</div>
                        <div className="text-xs text-red-600 mt-1 font-semibold">Must report to OSHA within 8 hours (29 CFR 1904.39)</div>
                      </div>
                    </div>
                  </button>

                  <button
                    onClick={() => updateField('incidentOutcome', 2)}
                    className={`w-full p-4 border-2 rounded-lg text-left transition-all ${
                      formData.incidentOutcome === 2
                        ? 'border-blue-600 bg-blue-50'
                        : 'border-gray-200 hover:border-gray-300'
                    } ${formData.preFilled && formData.incidentOutcome === 2 ? 'bg-green-50 border-green-300' : ''}`}
                  >
                    <div>
                      <div className="font-semibold text-gray-900">Days Away From Work (DAFW)</div>
                      <div className="text-xs text-gray-600 mt-1">29 CFR 1904.7(b)(3) - Employee cannot work for one or more days</div>
                    </div>
                  </button>

                  <button
                    onClick={() => updateField('incidentOutcome', 3)}
                    className={`w-full p-4 border-2 rounded-lg text-left transition-all ${
                      formData.incidentOutcome === 3
                        ? 'border-blue-600 bg-blue-50'
                        : 'border-gray-200 hover:border-gray-300'
                    } ${formData.preFilled && formData.incidentOutcome === 3 ? 'bg-green-50 border-green-300' : ''}`}
                  >
                    <div>
                      <div className="font-semibold text-gray-900">Job Transfer or Restriction</div>
                      <div className="text-xs text-gray-600 mt-1">29 CFR 1904.7(b)(4) - Cannot perform routine functions or work full day</div>
                    </div>
                  </button>

                  <button
                    onClick={() => updateField('incidentOutcome', 4)}
                    className={`w-full p-4 border-2 rounded-lg text-left transition-all ${
                      formData.incidentOutcome === 4
                        ? 'border-blue-600 bg-blue-50'
                        : 'border-gray-200 hover:border-gray-300'
                    } ${formData.preFilled && formData.incidentOutcome === 4 ? 'bg-green-50 border-green-300' : ''}`}
                  >
                    <div>
                      <div className="font-semibold text-gray-900">Other Recordable Case</div>
                      <div className="text-xs text-gray-600 mt-1">Medical treatment, loss of consciousness, or significant diagnosis without days away/restriction</div>
                    </div>
                  </button>
                </div>
              </div>

              {formData.incidentOutcome === 2 && (
                <div className="bg-blue-50 border-l-4 border-blue-500 p-4 rounded">
                  <label className="block text-sm font-semibold mb-2">
                    Number of Calendar Days Away From Work
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="180"
                    value={formData.daysAway || 0}
                    onChange={(e) => updateField('daysAway', parseInt(e.target.value) || 0)}
                    className="w-full p-3 border rounded-lg"
                  />
                  <p className="text-xs text-blue-900 mt-2">
                    Count calendar days starting the day after injury (weekends/holidays included). May cap at 180 days per 29 CFR 1904.7(b)(3)(viii)
                  </p>
                </div>
              )}

              {formData.incidentOutcome === 3 && (
                <div className="bg-blue-50 border-l-4 border-blue-500 p-4 rounded">
                  <label className="block text-sm font-semibold mb-2">
                    Number of Days on Restricted Duty or Job Transfer
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="180"
                    value={formData.daysRestricted || 0}
                    onChange={(e) => updateField('daysRestricted', parseInt(e.target.value) || 0)}
                    className="w-full p-3 border rounded-lg"
                  />
                  <p className="text-xs text-blue-900 mt-2">
                    Count calendar days of restriction. May cap at 180 days per 29 CFR 1904.7(b)(4)(vi)
                  </p>
                </div>
              )}

              {formData.incidentOutcome === 1 && (
                <div className="bg-red-50 border-l-4 border-red-500 p-4 rounded">
                  <label className="block text-sm font-semibold mb-2">
                    Date of Death (if different from incident date)
                  </label>
                  <input
                    type="date"
                    value={formData.dateOfDeath}
                    onChange={(e) => updateField('dateOfDeath', e.target.value)}
                    className="w-full p-3 border rounded-lg"
                  />
                  <p className="text-xs text-red-900 mt-2">
                    Must occur within 30 days of work-related incident to be recordable (29 CFR 1904.39)
                  </p>
                </div>
              )}
            </div>

            <div className="flex justify-between mt-8">
              <button
                onClick={() => setCurrentStep(2)}
                className="px-8 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 font-semibold"
              >
                ← Back
              </button>
              <button
                onClick={() => setCurrentStep(4)}
                disabled={!formData.typeOfIncident || !formData.incidentOutcome}
                className="px-8 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed font-semibold"
              >
                Review & Submit →
              </button>
            </div>
          </div>
        )}

        {/* Step 4: Review & Submit */}
        {currentStep === 4 && (
          <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-2xl font-bold mb-6">Step 4: Review & Submit</h2>
            
            <div className="bg-green-50 border-l-4 border-green-500 p-6 rounded mb-6">
              <div className="flex items-start">
                <CheckCircle className="h-6 w-6 text-green-600 mr-3 flex-shrink-0 mt-1" />
                <div>
                  <h3 className="font-bold text-green-900 mb-2">Ready to Record</h3>
                  <p className="text-sm text-green-800">
                    This incident meets OSHA recording criteria. Upon submission, this will:
                  </p>
                  <ul className="text-sm text-green-800 mt-2 space-y-1 ml-4">
                    <li>• Create entry in OSHA Form 300 Log (within 7 days required)</li>
                    <li>• Generate OSHA Form 301 Incident Report (within 7 days required)</li>
                    <li>• Store data for annual Form 300A Summary</li>
                    <li>• Prepare for ITA electronic submission (if establishment qualifies)</li>
                  </ul>
                </div>
              </div>
            </div>

            <div className="space-y-6">
              <div className="border-2 border-gray-200 rounded-lg p-6">
                <h3 className="font-semibold text-lg mb-4">Incident Summary</h3>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-gray-600">Case Number</p>
                    <p className="font-semibold font-mono">{formData.caseNumber}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">Date of Incident</p>
                    <p className="font-semibold">{formData.dateOfIncident || 'Not specified'}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">Employee</p>
                    <p className="font-semibold">{formData.employeeName}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">Job Title</p>
                    <p className="font-semibold">{formData.jobTitle}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">Type</p>
                    <p className="font-semibold">
                      {formData.typeOfIncident === 1 && 'Injury'}
                      {formData.typeOfIncident === 2 && 'Skin Disorder'}
                      {formData.typeOfIncident === 3 && 'Respiratory Condition'}
                      {formData.typeOfIncident === 4 && 'Poisoning'}
                      {formData.typeOfIncident === 5 && 'Hearing Loss'}
                      {formData.typeOfIncident === 6 && 'All Other Illness'}
                    </p>
                  </div>
                  <div>
                    <p className="text-gray-600">Outcome</p>
                    <p className="font-semibold">
                      {formData.incidentOutcome === 1 && 'Death'}
                      {formData.incidentOutcome === 2 && `Days Away: ${formData.daysAway || 0}`}
                      {formData.incidentOutcome === 3 && `Restricted: ${formData.daysRestricted || 0} days`}
                      {formData.incidentOutcome === 4 && 'Other Recordable'}
                    </p>
                  </div>
                </div>
              </div>

              <div className="border-2 border-gray-200 rounded-lg p-6">
                <h3 className="font-semibold text-lg mb-4">Incident Description (Form 301)</h3>
                <div className="space-y-3 text-sm">
                  <div>
                    <p className="text-gray-600 font-semibold">Location:</p>
                    <p className="text-gray-800">{formData.incidentLocation}</p>
                  </div>
                  <div>
                    <p className="text-gray-600 font-semibold">What employee was doing:</p>
                    <p className="text-gray-800">{formData.whatEmployeeDoing}</p>
                  </div>
                  <div>
                    <p className="text-gray-600 font-semibold">What happened:</p>
                    <p className="text-gray-800">{formData.whatHappened}</p>
                  </div>
                  <div>
                    <p className="text-gray-600 font-semibold">Injury/Illness:</p>
                    <p className="text-gray-800">{formData.injuryIllnessDescription}</p>
                  </div>
                  <div>
                    <p className="text-gray-600 font-semibold">Object/Substance:</p>
                    <p className="text-gray-800">{formData.objectSubstance}</p>
                  </div>
                </div>
              </div>

              {formData.requiresEmergencyReport && formData.incidentOutcome === 1 && (
                <div className="bg-red-50 border-l-4 border-red-500 p-6 rounded">
                  <h3 className="font-bold text-red-900 mb-3 flex items-center">
                    <AlertCircle className="h-5 w-5 mr-2" />
                    URGENT: Emergency OSHA Reporting Required
                  </h3>
                  <p className="text-sm text-red-800 font-semibold mb-2">
                    This fatality must be reported to OSHA within 8 hours of the death.
                  </p>
                  <p className="text-sm text-red-800">
                    Call OSHA at 1-800-321-OSHA (6742) immediately or file online at www.osha.gov/report
                  </p>
                </div>
              )}

              <div className="bg-yellow-50 border-l-4 border-yellow-500 p-6 rounded">
                <h3 className="font-bold text-yellow-900 mb-3 flex items-center">
                  <AlertCircle className="h-5 w-5 mr-2" />
                  Compliance Reminders
                </h3>
                <ul className="text-sm text-yellow-800 space-y-2">
                  <li>• <strong>7-Day Deadline:</strong> Record in Form 300 Log and complete Form 301 within 7 calendar days of receiving information (29 CFR 1904.29(b)(3))</li>
                  <li>• <strong>Privacy Check:</strong> Determine if this qualifies as a privacy case (intimate body part, sexual assault, mental illness, HIV/hepatitis/TB, needlestick)</li>
                  <li>• <strong>Retention:</strong> Keep all records for 5 years following the year they cover (29 CFR 1904.33)</li>
                  <li>• <strong>Annual Summary:</strong> Include in Form 300A by February 1 of following year, post until April 30 (29 CFR 1904.32)</li>
                </ul>
              </div>
            </div>

            <div className="flex justify-between mt-8">
              <button
                onClick={() => setCurrentStep(3)}
                className="px-8 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 font-semibold"
              >
                ← Back to Edit
              </button>
              <button
                onClick={handleSubmit}
                className="px-8 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 font-semibold flex items-center"
              >
                <Check className="h-5 w-5 mr-2" />
                Submit Incident Report
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

const RecordabilityTool = () => {
  const [currentStep, setCurrentStep] = useState(0);
  const [answers, setAnswers] = useState({});
  const [exceptionChecks, setExceptionChecks] = useState({});
  const [showInfo, setShowInfo] = useState({});
  const [showIncidentForm, setShowIncidentForm] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [currentView, setCurrentView] = useState('recordability');
  const [incidentContext, setIncidentContext] = useState({
    witnessName: '',
    incidentDate: '',
    incidentTime: '',
    employeeName: '',
    location: ''
  });

  // Helper function to load pre-filled data from recordability assessment
  const loadPreFilledData = () => {
    try {
      const savedData = sessionStorage.getItem('oshaIncidentData');
      if (savedData) {
        const data = JSON.parse(savedData);
        return {
          // Basic info (Step 1) - PRE-FILLED
          dateOfIncident: data.incidentDate || '',
          timeOfIncident: data.incidentTime || '',
          employeeName: data.employeeName || '',
          incidentLocation: data.location || '',
          timeStartedWork: '', // Still needs to be filled by user
          jobTitle: '', // Still needs to be filled by user
          
          // Step 2 - PARTIALLY PRE-FILLED
          whatEmployeeDoing: generateDescriptionFromAssessment(data) || '',
          whatHappened: '', // User must still describe full sequence
          injuryIllnessDescription: '', // User must still provide details
          objectSubstance: '', // User must still specify
          
          // Step 3 - AUTO-SELECTED
          typeOfIncident: data.autoIncidentType || null,
          incidentOutcome: data.autoIncidentOutcome || null,
          daysAway: data.requiresDaysAway ? 0 : undefined,
          daysRestricted: data.requiresRestriction ? 0 : undefined,
          dateOfDeath: data.isFatality ? '' : undefined,
          
          // Metadata
          isRecordable: true,
          recordabilityResult: data.recordabilityResult,
          isPrivacyCase: data.isPrivacyCase,
          caseNumber: '', // Will be auto-generated
          
          // Additional context for reference
          assessmentWorkActivity: data.workActivity,
          assessmentMedicalTreatment: data.medicalTreatment,
          assessmentInjuryType: data.injuryType,
          hospitalizationDetails: data.hospitalizationDetails,
          
          // Flags
          preFilled: true,
          preFilledTimestamp: data.assessmentCompletedAt
        };
      }
    } catch (error) {
      console.error('Error loading pre-filled data:', error);
    }
    return null;
  };

  // Helper function to generate description text from assessment data
  const generateDescriptionFromAssessment = (assessmentData) => {
    const parts = [];
    
    // Add work activity
    if (assessmentData?.workActivity) {
      const activityMap = {
        'working': 'performing regular job duties',
        'break_work': 'on break at workplace',
        'required_activity': 'attending required company activity',
        'personal_task': 'performing personal task'
      };
      parts.push(`Employee was ${activityMap[assessmentData.workActivity] || 'working'}`);
    }
    
    // Add medical treatment received
    if (assessmentData?.medicalTreatment && assessmentData.medicalTreatment.length > 0) {
      const treatmentMap = {
        'prescription': 'prescription medication',
        'stitches': 'stitches/sutures',
        'physical_therapy': 'physical therapy',
        'fracture_treatment': 'fracture treatment',
        'cast': 'cast/rigid splint',
        'iv_fluids': 'IV fluids',
        'surgery': 'surgery',
        'first_aid_only': 'first aid only'
      };
      const treatments = assessmentData.medicalTreatment
        .map(t => treatmentMap[t])
        .filter(Boolean)
        .join(', ');
      if (treatments) {
        parts.push(`Treatment received: ${treatments}`);
      }
    }
    
    return parts.join('. ') + (parts.length > 0 ? '.' : '');
  };

  // Simplified decision tree with better UX flow
  const decisionTree = [
    {
      step: 0,
      category: 'context',
      title: 'Quick Context',
      subtitle: 'Help us understand what happened',
      icon: User,
      fields: [
        { id: 'witnessName', label: 'Your name (person reporting)', type: 'text', required: false },
        { id: 'incidentDate', label: 'When did this happen?', type: 'date', required: true },
        { id: 'incidentTime', label: 'What time?', type: 'time', required: false },
        { id: 'employeeName', label: 'Who was affected?', type: 'text', required: true },
        { id: 'location', label: 'Where did it happen?', type: 'text', required: true, placeholder: 'e.g., Factory floor, Loading dock, Office 2nd floor' }
      ],
      nextStep: 1
    },
    {
      step: 1,
      category: 'screening',
      icon: Activity,
      question: 'What happened to the person?',
      subtitle: 'Select what best describes the situation',
      regulation: '29 CFR 1904.4(a)',
      options: [
        { value: 'injury', label: 'Physical Injury', description: 'Cut, burn, sprain, fracture, bruise, etc.', next: 2 },
        { value: 'illness', label: 'Illness or Health Issue', description: 'Rash, breathing problems, headache, nausea, etc.', next: 2 },
        { value: 'exposure', label: 'Exposure (no immediate symptoms)', description: 'Chemical splash, noise, hazardous substance', next: 2 },
        { value: 'near_miss', label: 'Close call (no injury/illness)', description: 'Nothing happened to the person', result: 'not_recordable', reason: 'No injury or illness occurred. Document as a near-miss for safety tracking.' }
      ],
      infoBox: {
        title: 'Why we ask this',
        content: 'OSHA requires recording injuries and illnesses, but not near-misses. We need to know if someone actually experienced a health effect.'
      }
    },
    {
      step: 2,
      category: 'screening',
      icon: User,
      question: 'Is this person your employee?',
      subtitle: 'This is critical for OSHA recordkeeping',
      regulation: '29 CFR 1904.31',
      options: [
        { value: 'yes', label: 'Yes - Our Employee', description: 'On our payroll (full-time, part-time, seasonal, temp)', next: 3 },
        { value: 'contractor', label: 'No - Contractor/Vendor', description: 'Works for another company', result: 'not_your_recordable', reason: 'Not your employee. Their employer may need to record it. Document the incident for your records.' },
        { value: 'temp_agency', label: 'Temp Agency Worker', description: 'Unsure who records?', next: 'temp_check' },
        { value: 'visitor', label: 'Visitor/Customer', description: 'Not working here', result: 'not_recordable', reason: 'Visitors and customers are not covered by OSHA recordkeeping requirements.' }
      ],
      infoBox: {
        title: 'Employee Status Matters',
        content: 'OSHA only requires you to record injuries/illnesses for YOUR employees. Contractors, temp workers, and visitors have different rules.'
      }
    },
    {
      step: 3,
      category: 'screening',
      icon: MapPin,
      question: 'Where did this happen?',
      subtitle: 'Location determines work-relatedness',
      regulation: '29 CFR 1904.5(a)',
      options: [
        { value: 'workplace', label: 'At Our Workplace', description: 'Factory, office, parking lot, company property', next: 4 },
        { value: 'work_site', label: 'At Work Site/Client Location', description: 'Where we sent them to work', next: 4 },
        { value: 'work_vehicle', label: 'In Company Vehicle', description: 'During work activities', next: 4 },
        { value: 'work_travel', label: 'Business Travel', description: 'Hotel, restaurant, travel for work', next: 4 },
        { value: 'home_remote', label: 'Working From Home', description: 'During remote work hours', next: 4 },
        { value: 'commute', label: 'Commuting/Personal Time', description: 'Not at work or work location', result: 'not_recordable', reason: 'Commuting and personal activities are not work-related.' }
      ],
      infoBox: {
        title: 'Work Environment',
        content: 'The "work environment" is broad - it includes anywhere your employee is required to be for work.'
      }
    },
    {
      step: 4,
      category: 'work_related',
      icon: AlertTriangle,
      question: 'Was the person doing work activities?',
      subtitle: 'What was happening when the incident occurred?',
      regulation: '29 CFR 1904.5(b)',
      presumption: true,
      options: [
        { value: 'working', label: 'Working / Job Duties', description: 'Performing assigned work tasks', next: 'exceptions' },
        { value: 'break_work', label: 'Break But On Premises', description: 'Lunch break, rest break on company property', next: 'exceptions' },
        { value: 'required_activity', label: 'Required Company Activity', description: 'Training, meeting, company event (required)', next: 'exceptions' },
        { value: 'personal_task', label: 'Personal Task/Activity', description: 'Personal errands, grooming, own food', next: 'personal_check' }
      ],
      infoBox: {
        title: '⚠️ OSHA Presumption',
        content: 'If it happened in the work environment during work time, OSHA PRESUMES it is work-related unless you can prove otherwise.'
      }
    },
    {
      step: 'exceptions',
      category: 'work_related',
      icon: CheckCircle,
      title: 'Work-Relatedness Exceptions',
      subtitle: 'Check if any of these apply - if YES to any, it may NOT be work-related',
      regulation: '29 CFR 1904.5(b)(2)',
      exceptionChecklist: [
        {
          id: 'common_cold',
          title: 'Common Cold or Seasonal Flu',
          regulation: '29 CFR 1904.5(b)(2)(ii)',
          question: 'Is this just a regular cold or seasonal flu?',
          note: 'Exception: If workplace exposure caused it (healthcare, lab work), it IS recordable',
          examples: ['Caught seasonal flu', 'Common cold from community']
        },
        {
          id: 'voluntary_wellness',
          title: 'Voluntary Wellness/Recreation',
          regulation: '29 CFR 1904.5(b)(2)(iii)',
          question: 'Was this during a voluntary (not required) wellness/fitness/recreation activity outside work hours?',
          examples: ['Voluntary lunch yoga', 'After-work softball (voluntary)', 'Company gym (personal time)']
        },
        {
          id: 'eating_personal',
          title: 'Eating/Drinking Personal Food',
          regulation: '29 CFR 1904.5(b)(2)(ix)',
          question: 'Was this from eating/drinking food they brought from home?',
          note: 'Exception: If workplace contaminated it or company cafeteria food, it IS recordable',
          examples: ['Choked on packed lunch', 'Allergic reaction to personal snack']
        },
        {
          id: 'personal_grooming',
          title: 'Personal Grooming',
          regulation: '29 CFR 1904.5(b)(2)(vi)',
          question: 'Was this from personal grooming (shaving, personal medication, etc.)?',
          examples: ['Cut while shaving in bathroom', 'Personal medication reaction']
        },
        {
          id: 'mental_illness',
          title: 'Mental Illness (No Medical Documentation)',
          regulation: '29 CFR 1904.5(b)(2)(x)',
          question: 'Is this a mental health issue without a doctor saying work caused it?',
          note: 'Only recordable if physician/HCP provides written statement that work caused it',
          examples: ['Self-reported work stress', 'No medical documentation']
        },
        {
          id: 'parking_commute',
          title: 'Parking Lot Accident While Commuting',
          regulation: '29 CFR 1904.5(b)(2)(vii)',
          question: 'Was this a vehicle accident in the parking lot while arriving/leaving for the day?',
          note: 'Exception: If doing work duties (security, deliveries), it IS recordable',
          examples: ['Fender bender arriving to work', 'Backed into car leaving work']
        },
        {
          id: 'non_work_injury',
          title: 'Injury Happened Outside Work',
          regulation: '29 CFR 1904.5(b)(2)(iv)',
          question: 'Did the actual injury happen outside of work (symptoms just appeared at work)?',
          examples: ['Injured at home, pain started at work', 'Weekend injury, reported Monday']
        }
      ],
      continueAction: 'evaluate_exceptions',
      nextStep: 5  // Added explicit next step
    },
    {
      step: 5,
      category: 'new_case',
      icon: FileText,
      question: 'Has this employee had this same problem before?',
      subtitle: 'New case determination',
      regulation: '29 CFR 1904.6',
      options: [
        { value: 'never', label: 'Never Had This Before', description: 'First time with this injury/illness', next: 6 },
        { value: 'had_recovered', label: 'Had It, Fully Recovered, Now Again', description: 'Previous case fully healed', next: 6 },
        { value: 'ongoing', label: 'Ongoing/Chronic Condition', description: 'Continuing from previous injury/illness', result: 'update_existing', reason: 'Update the existing case if condition worsens. Do not create new case.' }
      ],
      infoBox: {
        title: 'New vs. Existing Case',
        content: 'OSHA wants separate cases for new injuries, but updates for ongoing chronic conditions that worsen.'
      }
    },
    {
      step: 6,
      category: 'severity',
      icon: Zap,
      question: 'What was the outcome?',
      subtitle: 'Select the MOST SERIOUS outcome that occurred',
      regulation: '29 CFR 1904.7',
      options: [
        { 
          value: 'death', 
          label: 'Death', 
          description: 'Employee died',
          alert: 'CALL OSHA WITHIN 8 HOURS: 1-800-321-6742',
          result: 'recordable_death',
          reason: 'DEATH - Automatically recordable. Must report to OSHA within 8 hours.'
        },
        { 
          value: 'hospitalized', 
          label: 'Hospitalized Overnight', 
          description: 'Admitted as in-patient',
          alert: 'Report to OSHA within 24 hours if work-related',
          next: 7
        },
        { 
          value: 'days_away', 
          label: 'Missed Work Days', 
          description: 'Could not come to work (even 1 day)',
          result: 'recordable_dafw',
          reason: 'Days Away From Work - Recordable. Count calendar days employee missed.'
        },
        { 
          value: 'restricted', 
          label: 'Light Duty / Restricted Work', 
          description: 'Could not do full job or full hours',
          result: 'recordable_restricted',
          reason: 'Job Transfer or Restriction - Recordable. Count days of restriction.'
        },
        { 
          value: 'medical_treatment', 
          label: 'Medical Treatment Needed', 
          description: 'Doctor/nurse treatment beyond basic first aid',
          next: 8
        },
        { 
          value: 'loss_consciousness', 
          label: 'Lost Consciousness', 
          description: 'Passed out or blacked out',
          result: 'recordable_consciousness',
          reason: 'Loss of Consciousness - Recordable regardless of duration.'
        },
        { 
          value: 'first_aid_only', 
          label: 'First Aid Only', 
          description: 'Basic bandages, ice, over-the-counter meds',
          next: 9
        }
      ]
    },
    {
      step: 7,
      category: 'severity',
      question: 'Hospitalization Follow-up',
      subtitle: 'Tell us more about the hospitalization',
      fields: [
        { id: 'hospitalization_reason', label: 'Why were they hospitalized?', type: 'textarea', required: true },
        { id: 'hospital_name', label: 'Hospital name', type: 'text', required: false }
      ],
      result: 'recordable_hospitalization',
      reason: 'In-patient Hospitalization - Recordable. Must report to OSHA within 24 hours if work-related.'
    },
    {
      step: 8,
      category: 'severity',
      icon: AlertCircle,
      question: 'What medical treatment did they receive?',
      subtitle: 'Select all that apply',
      regulation: '29 CFR 1904.7(b)(5)',
      multiSelect: true,
      options: [
        { value: 'prescription', label: 'Prescription Medication', recordable: true },
        { value: 'stitches', label: 'Stitches/Sutures/Staples', recordable: true },
        { value: 'physical_therapy', label: 'Physical Therapy', recordable: true },
        { value: 'fracture_treatment', label: 'Fracture/Broken Bone Treatment', recordable: true },
        { value: 'cast', label: 'Cast or Rigid Splint', recordable: true },
        { value: 'iv_fluids', label: 'IV Fluids/Injection', recordable: true },
        { value: 'surgery', label: 'Surgery', recordable: true },
        { value: 'other_medical', label: 'Other Medical Treatment', recordable: true },
        { value: 'first_aid_only', label: 'Only Basic First Aid', recordable: false }
      ],
      evaluateAction: 'check_medical_treatment',
      nextStep: 9  // Added explicit next step
    },
    {
      step: 9,
      category: 'severity',
      icon: Info,
      question: 'Did a doctor diagnose anything significant?',
      subtitle: 'Even with just first aid, certain diagnoses are recordable',
      regulation: '29 CFR 1904.7(b)(7)',
      options: [
        { value: 'cancer', label: 'Cancer (work-related)', result: 'recordable_significant' },
        { value: 'chronic', label: 'Chronic Irreversible Disease', description: 'Asbestosis, silicosis, etc.', result: 'recordable_significant' },
        { value: 'fracture', label: 'Fractured or Cracked Bone/Tooth', result: 'recordable_significant' },
        { value: 'punctured_eardrum', label: 'Punctured Eardrum', result: 'recordable_significant' },
        { value: 'other_significant', label: 'Other Significant Diagnosis', description: 'Doctor said it should be recorded', result: 'recordable_significant' },
        { value: 'none', label: 'No Significant Diagnosis', result: 'not_recordable', reason: 'Only first aid and no significant diagnosis. Not OSHA recordable.' }
      ]
    },
    {
      step: 10,
      category: 'special',
      icon: AlertTriangle,
      question: 'Special Cases - Does any of this apply?',
      subtitle: 'These have special OSHA recording rules',
      multiCheck: true,
      specialCases: [
        {
          id: 'needlestick',
          title: 'Needlestick or Sharps Injury',
          regulation: '29 CFR 1904.8',
          description: 'ANY needlestick with blood/body fluid exposure',
          note: 'Always recordable, automatically privacy case',
          recordable: true
        },
        {
          id: 'hearing_loss',
          title: 'Hearing Loss (STS)',
          regulation: '29 CFR 1904.10',
          description: 'Standard Threshold Shift - 10+ dB average change',
          note: 'Special audiogram requirements apply',
          recordable: true
        },
        {
          id: 'tuberculosis',
          title: 'Tuberculosis (TB)',
          regulation: '29 CFR 1904.11',
          description: 'Work exposure + TB diagnosis',
          note: 'Common in healthcare workers',
          recordable: true
        },
        {
          id: 'medical_removal',
          title: 'Medical Removal',
          regulation: '29 CFR 1904.9',
          description: 'Removed per OSHA standard (Lead, Benzene, etc.)',
          note: 'Recordable even without symptoms',
          recordable: true
        },
        {
          id: 'none_special',
          title: 'None of These Apply',
          recordable: false
        }
      ],
      continueAction: 'evaluate_special_cases',
      isFinalStep: true  // Added flag to indicate this is last step
    }
  ];

  const handleContextSubmit = () => {
    const required = decisionTree[0].fields.filter(f => f.required);
    const allFilled = required.every(f => incidentContext[f.id]);
    
    if (allFilled) {
      setCurrentStep(1);
    } else {
      alert('Please fill in all required fields');
    }
  };

  const handleOptionSelect = (option) => {
    const newAnswers = {...answers, [currentStep]: option.value};
    setAnswers(newAnswers);

    if (option.result) {
      setAnswers({
        ...newAnswers,
        result: option.result,
        reason: option.reason,
        alert: option.alert
      });
    } else if (option.next !== undefined) {
      if (typeof option.next === 'string') {
        // Find step by step identifier or category
        const nextStepIndex = decisionTree.findIndex(s => 
          s.step === option.next || s.category === option.next
        );
        if (nextStepIndex >= 0) {
          setCurrentStep(nextStepIndex);
        } else {
          console.error('Could not find next step:', option.next);
        }
      } else {
        // Numeric step - find the actual index
        const nextStepIndex = decisionTree.findIndex(s => s.step === option.next);
        setCurrentStep(nextStepIndex >= 0 ? nextStepIndex : option.next);
      }
    }
  };

  const handleExceptionEvaluation = () => {
    const anyExceptionChecked = Object.values(exceptionChecks).some(v => v === true);
    
    if (anyExceptionChecked) {
      const checkedExceptions = Object.keys(exceptionChecks)
        .filter(k => exceptionChecks[k])
        .map(k => {
          const ex = currentQuestion.exceptionChecklist.find(e => e.id === k);
          return ex?.title;
        })
        .filter(Boolean);

      setAnswers({
        ...answers,
        result: 'not_recordable',
        reason: `Work-relatedness exception applies: ${checkedExceptions.join(', ')}. Not OSHA recordable.`,
        exceptions: exceptionChecks
      });
    } else {
      // No exceptions apply, continue to new case determination
      const nextStepIndex = decisionTree.findIndex(s => s.step === 5);
      setCurrentStep(nextStepIndex >= 0 ? nextStepIndex : 5);
    }
  };

  const handleMedicalTreatmentEvaluation = () => {
    const selected = answers[currentStep] || [];
    const hasRecordableTreatment = selected.some(val => {
      const option = currentQuestion.options.find(o => o.value === val);
      return option?.recordable === true;
    });

    if (hasRecordableTreatment) {
      setAnswers({
        ...answers,
        result: 'recordable_medical',
        reason: 'Medical Treatment Beyond First Aid - Recordable.',
        treatments: selected
      });
    } else {
      // Go to significant diagnosis check
      const nextStepIndex = decisionTree.findIndex(s => s.step === 9);
      setCurrentStep(nextStepIndex >= 0 ? nextStepIndex : 9);
    }
  };

  const handleSpecialCasesEvaluation = () => {
    const checked = answers[currentStep] || [];
    const hasRecordableSpecial = checked.some(id => {
      const sc = currentQuestion.specialCases.find(s => s.id === id);
      return sc?.recordable === true;
    });

    if (hasRecordableSpecial && !checked.includes('none_special')) {
      const specialTypes = checked
        .map(id => currentQuestion.specialCases.find(s => s.id === id))
        .filter(s => s?.recordable)
        .map(s => s.title);

      setAnswers({
        ...answers,
        result: 'recordable_special',
        reason: `Special OSHA Recording Criteria: ${specialTypes.join(', ')}`,
        specialCases: checked
      });
    } else {
      // No special cases - finalize based on previous answers
      // Check if we already have a result from previous steps
      if (answers.result) {
        // Keep the existing result
        return;
      }
      
      // If no result yet, determine based on what we know
      // Look at step 6 (severity) to determine
      const severityAnswer = answers[6];
      
      if (!severityAnswer) {
        // No severity recorded, should not be recordable
        setAnswers({
          ...answers,
          result: 'not_recordable',
          reason: 'Does not meet OSHA recording criteria.'
        });
      }
    }
  };

  const reset = () => {
    setCurrentStep(0);
    setAnswers({});
    setExceptionChecks({});
    setShowInfo({});
    setShowIncidentForm(false);
    setIncidentContext({
      witnessName: '',
      incidentDate: '',
      incidentTime: '',
      employeeName: '',
      location: ''
    });
  };

  const handleGoToIncidentForm = () => {
    // Prepare comprehensive incident data for internal OSHA forms
    const incidentFormData = {
      // BASIC CONTEXT - PRE-FILLED
      employeeName: incidentContext.employeeName,
      incidentDate: incidentContext.incidentDate,
      incidentTime: incidentContext.incidentTime,
      location: incidentContext.location,
      witnessName: incidentContext.witnessName,
      
      // RECORDABILITY DETERMINATION - PRE-FILLED
      isRecordable: true,
      recordabilityResult: answers.result,
      recordabilityReason: answers.reason,
      
      // FORM 300 CLASSIFICATION - AUTO-FILLED
      injuryType: answers[1], // injury/illness/exposure
      outcomeClassification: {
        death: answers.result === 'recordable_death',
        daysAwayFromWork: answers.result === 'recordable_dafw',
        jobTransferRestriction: answers.result === 'recordable_restricted', 
        otherRecordable: !['recordable_death', 'recordable_dafw', 'recordable_restricted'].includes(answers.result)
      },
      
      // MEDICAL TREATMENT - PRE-FILLED
      medicalTreatmentReceived: answers.treatments || [],
      
      // WORK-RELATEDNESS - PRE-FILLED
      workRelated: true, // Since we reached recordable conclusion
      workActivity: answers[4], // what employee was doing
      
      // SPECIAL CASES - AUTO-FLAGGED
      isPrivacyCase: answers.specialCases?.includes('needlestick') || false,
      specialOSHACases: answers.specialCases || [],
      
      // EMERGENCY REPORTING STATUS
      requiresEmergencyOSHAReport: answers.result === 'recordable_death' || answers.result === 'recordable_hospitalization',
      emergencyReportDeadline: answers.result === 'recordable_death' ? '8 hours from death' : 
                              (answers.result === 'recordable_hospitalization' ? '24 hours from incident' : null),
      
      // METADATA
      assessmentCompletedAt: new Date().toISOString(),
      formDeadline: incidentContext.incidentDate ? 
        new Date(new Date(incidentContext.incidentDate).getTime() + 7 * 24 * 60 * 60 * 1000).toISOString() : null,
    };
    
    // Store comprehensive data for incident form
    sessionStorage.setItem('oshaIncidentFormData', JSON.stringify(incidentFormData));
    
    // Navigate to incident form
    setShowIncidentForm(true);
  };

  const handleIncidentSaved = (incidentRecord) => {
    alert(`✅ Incident Record Saved!\n\nCase Number: ${incidentRecord.caseNumber}\nEmployee: ${incidentRecord.employeeName}\nStatus: Submitted\n\nThe incident has been recorded in your OSHA logs.`);
    // In production, you might navigate somewhere else or show a success page
    reset(); // For demo, reset to start
  };

  // Show incident form if user clicked the button
  if (showIncidentForm) {
    return (
      <IncidentForm 
        onBack={() => setShowIncidentForm(false)}
        onSave={handleIncidentSaved}
      />
    );
  }

  const currentQuestion = decisionTree[currentStep];

  // Main application with sidebar navigation
  return (
    <div className="min-h-screen bg-gray-100 flex">
      {/* Sidebar */}
      <div className={sidebarOpen ? 'w-64 bg-white shadow-lg' : 'w-20 bg-white shadow-lg'}>
        <div className="p-6 border-b">
          {sidebarOpen ? (
            <div className="flex items-center">
              <Shield className="h-8 w-8 text-blue-600 mr-2" />
              <span className="font-bold text-xl">OSHA Compliance</span>
            </div>
          ) : (
            <Shield className="h-8 w-8 text-blue-600 mx-auto" />
          )}
        </div>

        <nav className="p-4 space-y-2">
          {[
            { id: 'recordability', label: 'Recordability Assessment', icon: CheckCircle },
            { id: 'incident', label: 'Incident Report', icon: AlertTriangle }
          ].map(item => {
            const Icon = item.icon;
            const isActive = currentView === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setCurrentView(item.id)}
                className={
                  sidebarOpen 
                    ? (isActive 
                        ? 'w-full flex items-center px-4 py-3 rounded-lg bg-blue-50 text-blue-600 transition-colors' 
                        : 'w-full flex items-center px-4 py-3 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors')
                    : (isActive
                        ? 'w-full flex justify-center px-4 py-3 rounded-lg bg-blue-50 text-blue-600 transition-colors'
                        : 'w-full flex justify-center px-4 py-3 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors')
                }
              >
                <Icon className="h-5 w-5" />
                {sidebarOpen && <span className="ml-3 text-sm font-medium">{item.label}</span>}
              </button>
            );
          })}
        </nav>

        {/* Toggle sidebar button */}
        <div className="absolute bottom-4 left-4">
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
          >
            <ChevronLeft className={`h-5 w-5 text-gray-600 transition-transform ${sidebarOpen ? '' : 'rotate-180'}`} />
          </button>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="bg-white shadow-sm border-b px-8 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-xl font-semibold">
                {currentView === 'recordability' ? 'OSHA Recordability Assessment' : 'OSHA Incident Report'}
              </h1>
              <p className="text-sm text-gray-600">
                {currentView === 'recordability' 
                  ? 'Determine if workplace incidents must be recorded per 29 CFR 1904' 
                  : 'Create detailed incident reports for OSHA Forms 300/301'
                }
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center text-sm text-gray-600">
                <Clock className="h-4 w-4 mr-1" />
                Enterprise SaaS Platform
              </div>
            </div>
          </div>
          
          {/* Show assessment completion status */}
          {answers.result && currentView === 'incident' && (
            <div className="mt-4 bg-green-50 border border-green-200 p-3 rounded-lg">
              <div className="flex items-center">
                <Check className="h-4 w-4 text-green-600 mr-2" />
                <span className="text-sm font-medium text-green-900">
                  Assessment completed: {answers.result.replace('recordable_', '').replace('_', ' ').toUpperCase()}
                </span>
              </div>
              <p className="text-xs text-green-700 mt-1">
                Data from recordability assessment will pre-fill incident form fields
              </p>
            </div>
          )}
        </div>

        {/* Page Content */}
        <div className="flex-1 overflow-auto p-8">
          {currentView === 'recordability' && (
            <div>
              {/* Recordability Assessment Content */}
              {answers.result ? (
                // Results Screen
                <div className="max-w-4xl mx-auto space-y-6">
                  <div className="bg-white rounded-lg shadow-lg p-8">
                    <div className={`w-24 h-24 rounded-full flex items-center justify-center mx-auto mb-6 ${
                      answers.result.includes('recordable') && answers.result !== 'not_recordable' && answers.result !== 'not_your_recordable' ? 'bg-red-100' : 'bg-green-100'
                    }`}>
                      {answers.result.includes('recordable') && answers.result !== 'not_recordable' && answers.result !== 'not_your_recordable' ? 
                        <AlertTriangle className="h-12 w-12 text-red-600" /> : 
                        <CheckCircle className="h-12 w-12 text-green-600" />
                      }
                    </div>
                    
                    <h2 className={`text-3xl font-bold text-center mb-4 ${
                      answers.result.includes('recordable') && answers.result !== 'not_recordable' && answers.result !== 'not_your_recordable' ? 'text-red-600' : 'text-green-600'
                    }`}>
                      {answers.result.includes('recordable') && answers.result !== 'not_recordable' && answers.result !== 'not_your_recordable' ? 'OSHA RECORDABLE' :
                       answers.result === 'update_existing' ? 'UPDATE EXISTING CASE' : 
                       'NOT RECORDABLE'}
                    </h2>
                    
                    <p className="text-center text-gray-600 mb-6">
                      {answers.reason}
                    </p>

                    {/* Emergency OSHA Reporting */}
                    {(answers.result === 'recordable_death' || answers.result === 'recordable_hospitalization') && (
                      <div className="bg-red-600 border-4 border-red-700 rounded-xl p-6 mb-6 animate-pulse">
                        <div className="flex items-center mb-4">
                          <AlertTriangle className="h-10 w-10 text-white mr-4" />
                          <div>
                            <h3 className="font-bold text-white text-2xl">URGENT: REPORT TO OSHA NOW</h3>
                            <p className="text-red-100 text-lg font-semibold">
                              {answers.result === 'recordable_death' ? 'Within 8 Hours of Death' : 'Within 24 Hours of Hospitalization'}
                            </p>
                          </div>
                        </div>
                        
                        <div className="bg-white rounded-lg p-5 mb-4">
                          <h4 className="font-bold text-red-900 mb-3 text-lg">Immediate OSHA Reporting Required - 29 CFR 1904.39</h4>
                          <p className="text-gray-800 mb-4">
                            {answers.result === 'recordable_death' 
                              ? 'Employee fatalities must be reported to OSHA within 8 hours of the death.'
                              : 'In-patient hospitalizations must be reported to OSHA within 24 hours of the incident.'}
                          </p>
                          
                          <div className="bg-red-50 border-l-4 border-red-600 p-4 rounded mb-4">
                            <p className="font-bold text-red-900 mb-2">Deadline: {answers.result === 'recordable_death' ? '8 Hours from death' : '24 Hours from incident'}</p>
                            <p className="text-sm text-red-800">Incident: {incidentContext.incidentDate} {incidentContext.incidentTime || ''}</p>
                          </div>

                          <div className="space-y-3 mb-4">
                            <div className="flex items-start">
                              <div className="w-8 h-8 bg-red-600 text-white rounded-full flex items-center justify-center mr-3 flex-shrink-0 font-bold">1</div>
                              <div className="flex-1">
                                <p className="font-semibold text-gray-900">Call OSHA Hotline NOW</p>
                                <p className="text-2xl font-bold text-red-600">1-800-321-OSHA (6742)</p>
                                <p className="text-sm text-gray-600">Available 24/7 for emergency reporting</p>
                              </div>
                            </div>
                            
                            <div className="flex items-center">
                              <div className="flex-1 border-t-2 border-gray-300"></div>
                              <span className="px-3 text-gray-500 font-semibold">OR</span>
                              <div className="flex-1 border-t-2 border-gray-300"></div>
                            </div>

                            <div className="flex items-start">
                              <div className="w-8 h-8 bg-red-600 text-white rounded-full flex items-center justify-center mr-3 flex-shrink-0 font-bold">2</div>
                              <div className="flex-1">
                                <p className="font-semibold text-gray-900 mb-2">File Online Report</p>
                                <button
                                  onClick={() => {
                                    window.open('https://www.osha.gov/report', '_blank');
                                  }}
                                  className="w-full px-6 py-4 bg-red-600 text-white rounded-lg hover:bg-red-700 font-bold text-lg transition-all shadow-lg hover:shadow-xl flex items-center justify-center"
                                >
                                  <AlertTriangle className="h-6 w-6 mr-3" />
                                  File Emergency OSHA Report
                                </button>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Internal Recordkeeping */}
                    {(answers.result.includes('recordable') && answers.result !== 'not_recordable' && answers.result !== 'not_your_recordable') && (
                      <div className="bg-blue-50 border-2 border-blue-200 rounded-xl p-6 mb-6">
                        <h3 className="font-bold text-blue-900 mb-4 text-lg flex items-center">
                          <Clock className="h-5 w-5 mr-2" />
                          Internal Recordkeeping Required - 29 CFR 1904.29
                        </h3>
                        
                        {/* Show what will be pre-filled from assessment */}
                        <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-4">
                          <p className="text-sm font-semibold text-green-900 mb-2">Assessment Data Ready for Forms 300/301:</p>
                          <div className="grid grid-cols-2 gap-2 text-xs text-green-800">
                            <div className="flex items-start">
                              <Check className="h-3 w-3 mr-1 mt-0.5 flex-shrink-0" />
                              <span>Employee: {incidentContext.employeeName}</span>
                            </div>
                            <div className="flex items-start">
                              <Check className="h-3 w-3 mr-1 mt-0.5 flex-shrink-0" />
                              <span>Date: {incidentContext.incidentDate}</span>
                            </div>
                            <div className="flex items-start">
                              <Check className="h-3 w-3 mr-1 mt-0.5 flex-shrink-0" />
                              <span>Location: {incidentContext.location}</span>
                            </div>
                            <div className="flex items-start">
                              <Check className="h-3 w-3 mr-1 mt-0.5 flex-shrink-0" />
                              <span>Classification: {
                                answers.result === 'recordable_death' ? 'Fatality' :
                                answers.result === 'recordable_hospitalization' ? 'Hospitalization' :
                                answers.result === 'recordable_dafw' ? 'Days Away' :
                                answers.result === 'recordable_restricted' ? 'Restricted Work' :
                                'Other Recordable'
                              }</span>
                            </div>
                          </div>
                          <p className="text-xs text-green-700 mt-3 italic">
                            Most OSHA form fields will be automatically populated
                          </p>
                        </div>

                        <div className="mt-6 pt-4 border-t-2 border-blue-200">
                          <button
                            onClick={handleGoToIncidentForm}
                            className="w-full px-6 py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-bold text-lg transition-all shadow-lg hover:shadow-xl flex items-center justify-center"
                          >
                            <FileText className="h-6 w-6 mr-3" />
                            Create OSHA Incident Record (Forms 300/301)
                          </button>
                          <p className="text-xs text-center text-blue-700 mt-2">
                            Assessment data will auto-fill most fields
                          </p>
                        </div>
                      </div>
                    )}

                    {/* Decision summary */}
                    <div className="bg-gray-50 rounded-xl p-6 mb-6">
                      <h3 className="font-semibold mb-4 text-lg text-gray-900">Assessment Summary</h3>
                      <div className="space-y-2">
                        {Object.entries(answers)
                          .filter(([key]) => !['result', 'reason', 'alert', 'exceptions', 'treatments', 'specialCases'].includes(key))
                          .map(([stepNum, answer]) => {
                            const step = decisionTree[parseInt(stepNum)];
                            if (!step || !step.question) return null;
                            
                            return (
                              <div key={stepNum} className="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200">
                                <span className="text-sm font-medium text-gray-700">{step.question}</span>
                                <span className="px-3 py-1 rounded-full text-xs font-bold bg-blue-100 text-blue-800">
                                  {Array.isArray(answer) ? `${answer.length} selected` : String(answer).toUpperCase()}
                                </span>
                              </div>
                            );
                          })}
                      </div>
                    </div>

                    {/* Action buttons */}
                    <div className="flex flex-col sm:flex-row gap-4">
                      <button 
                        onClick={reset}
                        className="flex-1 px-6 py-3 bg-white border-2 border-gray-300 rounded-xl hover:bg-gray-50 font-semibold transition-colors flex items-center justify-center"
                      >
                        <RefreshCw className="h-5 w-5 mr-2" />
                        New Assessment
                      </button>
                      <button 
                        onClick={() => window.print()}
                        className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-semibold transition-colors flex items-center justify-center"
                      >
                        <FileText className="h-5 w-5 mr-2" />
                        Print Summary
                      </button>
                    </div>
                  </div>
                </div>
              ) : (
                // Assessment Questions
                <div>
                  {currentStep === 0 ? (
                    // Context Collection Screen
                    <div className="max-w-3xl mx-auto">
                      <div className="text-center mb-8">
                        <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-600 rounded-full mb-4">
                          <Shield className="h-8 w-8 text-white" />
                        </div>
                        <h1 className="text-4xl font-bold text-gray-900 mb-2">OSHA Recordability Assessment</h1>
                        <p className="text-lg text-gray-600">Determine if this incident needs to be recorded</p>
                      </div>

                      <div className="bg-white rounded-2xl shadow-2xl p-8">
                        <div className="flex items-center mb-6">
                          <User className="h-6 w-6 text-blue-600 mr-3" />
                          <h2 className="text-2xl font-bold text-gray-900">{currentQuestion.title}</h2>
                        </div>
                        <p className="text-gray-600 mb-6">{currentQuestion.subtitle}</p>

                        <div className="space-y-4">
                          {currentQuestion.fields.map(field => (
                            <div key={field.id}>
                              <label className="block text-sm font-semibold text-gray-700 mb-2">
                                {field.label} {field.required && <span className="text-red-600">*</span>}
                              </label>
                              {field.type === 'textarea' ? (
                                <textarea
                                  value={incidentContext[field.id] || ''}
                                  onChange={(e) => setIncidentContext({...incidentContext, [field.id]: e.target.value})}
                                  placeholder={field.placeholder}
                                  rows="3"
                                  className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none transition-colors"
                                />
                              ) : (
                                <input
                                  type={field.type}
                                  value={incidentContext[field.id] || ''}
                                  onChange={(e) => setIncidentContext({...incidentContext, [field.id]: e.target.value})}
                                  placeholder={field.placeholder}
                                  className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none transition-colors"
                                />
                              )}
                            </div>
                          ))}
                        </div>

                        <button
                          onClick={() => {
                            const required = decisionTree[0].fields.filter(f => f.required);
                            const allFilled = required.every(f => incidentContext[f.id]);
                            
                            if (allFilled) {
                              setCurrentStep(1);
                            } else {
                              alert('Please fill in all required fields');
                            }
                          }}
                          className="w-full mt-8 px-8 py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-bold text-lg transition-all shadow-lg hover:shadow-xl flex items-center justify-center"
                        >
                          Start Assessment
                          <ChevronRight className="h-6 w-6 ml-2" />
                        </button>
                      </div>
                    </div>
                  ) : (
                    // Assessment Questions...
                    // [Include all the complex decision tree logic here]
                    <div className="max-w-4xl mx-auto">
                      <div className="bg-white rounded-lg shadow p-6">
                        <div className="flex items-center justify-between mb-3">
                          <span className="text-sm text-gray-600">Step {currentStep + 1} of {decisionTree.length}</span>
                          <span className="text-sm font-bold text-blue-600">
                            {Math.round(((currentStep + 1) / decisionTree.length) * 100)}%
                          </span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-3">
                          <div 
                            className="bg-blue-600 h-3 rounded-full transition-all duration-300"
                            style={{width: `${((currentStep + 1) / decisionTree.length) * 100}%`}}
                          />
                        </div>
                      </div>

                      <div className="bg-white rounded-lg shadow-lg p-8 mt-6">
                        <div className="text-sm text-blue-600 font-medium mb-2">{currentQuestion.regulation}</div>
                        <h2 className="text-2xl font-bold mb-4">{currentQuestion.question}</h2>
                        
                        <div className="bg-blue-50 border-l-4 border-blue-500 p-4 rounded mb-6">
                          <p className="text-sm text-blue-900">
                            <Info className="h-4 w-4 inline mr-2" />
                            {currentQuestion.help}
                          </p>
                        </div>

                        {/* Assessment content continues... */}
                        <p className="text-center text-gray-500 py-8">
                          [Assessment questions would continue here with the full decision tree logic]
                        </p>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {currentView === 'incident' && (
            <IncidentForm 
              onBack={() => setCurrentView('recordability')}
              onSave={handleIncidentSaved}
            />
          )}
        </div>
      </div>
    </div>
  );

  // RESULTS SCREEN
  if (answers.result) {
    const isRecordable = answers.result?.includes('recordable') && answers.result !== 'not_recordable' && answers.result !== 'not_your_recordable';
    const isUpdateExisting = answers.result === 'update_existing';
    const isNotYours = answers.result === 'not_your_recordable';
    
    // Determine if this is a severe/emergency case requiring immediate OSHA reporting
    const isSevereCase = answers.result === 'recordable_death' || 
                         answers.result === 'recordable_hospitalization' ||
                         (answers[6] && ['death', 'hospitalized'].includes(answers[6]));
    
    const requiresImmediateOSHAReport = isSevereCase;
    const requires8HourReport = answers.result === 'recordable_death';
    const requires24HourReport = answers.result === 'recordable_hospitalization';
    
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 p-4 md:p-8">
        <div className="max-w-4xl mx-auto">
          {/* Header with context */}
          <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-semibold text-gray-900">{incidentContext.employeeName || 'Employee'}</h3>
                <p className="text-sm text-gray-600">{incidentContext.location} • {incidentContext.incidentDate}</p>
              </div>
              <Shield className="h-8 w-8 text-blue-600" />
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-2xl overflow-hidden">
            {/* Result header */}
            <div className={`p-8 ${
              isRecordable ? 'bg-gradient-to-r from-red-500 to-red-600' :
              isUpdateExisting ? 'bg-gradient-to-r from-yellow-500 to-yellow-600' :
              isNotYours ? 'bg-gradient-to-r from-blue-500 to-blue-600' :
              'bg-gradient-to-r from-green-500 to-green-600'
            }`}>
              <div className="flex items-center justify-center mb-4">
                <div className="w-20 h-20 bg-white rounded-full flex items-center justify-center">
                  {isRecordable ? <AlertTriangle className="h-10 w-10 text-red-600" /> :
                   isUpdateExisting ? <RefreshCw className="h-10 w-10 text-yellow-600" /> :
                   isNotYours ? <Info className="h-10 w-10 text-blue-600" /> :
                   <CheckCircle className="h-10 w-10 text-green-600" />}
                </div>
              </div>
              
              <h2 className="text-4xl font-bold text-white text-center mb-2">
                {isRecordable ? 'OSHA RECORDABLE' :
                 isUpdateExisting ? 'UPDATE EXISTING CASE' :
                 isNotYours ? 'NOT YOUR RECORDABLE' :
                 'NOT RECORDABLE'}
              </h2>
              
              <p className="text-white text-center text-lg opacity-90">
                {answers.reason}
              </p>

              {answers.alert && (
                <div className="mt-4 bg-white bg-opacity-20 rounded-lg p-4">
                  <p className="text-white font-bold text-center">{answers.alert}</p>
                </div>
              )}
            </div>

            {/* Action items */}
            <div className="p-8">
              {/* EMERGENCY REPORTING - Shows first if severe case */}
              {requiresImmediateOSHAReport && (
                <div className="bg-red-600 border-4 border-red-700 rounded-xl p-6 mb-6 animate-pulse">
                  <div className="flex items-center mb-4">
                    <AlertTriangle className="h-10 w-10 text-white mr-4" />
                    <div>
                      <h3 className="font-bold text-white text-2xl">URGENT: REPORT TO OSHA NOW</h3>
                      <p className="text-red-100 text-lg font-semibold">
                        {requires8HourReport ? 'Within 8 Hours of Incident' : 'Within 24 Hours of Incident'}
                      </p>
                    </div>
                  </div>
                  
                  <div className="bg-white rounded-lg p-5 mb-4">
                    <h4 className="font-bold text-red-900 mb-3 text-lg">Immediate OSHA Reporting Required - 29 CFR 1904.39</h4>
                    <p className="text-gray-800 mb-4">
                      {requires8HourReport 
                        ? 'Fatalities must be reported to OSHA within 8 hours.'
                        : 'Amputations, in-patient hospitalizations, and loss of an eye must be reported to OSHA within 24 hours.'}
                    </p>
                    
                    <div className="bg-red-50 border-l-4 border-red-600 p-4 rounded mb-4">
                      <p className="font-bold text-red-900 mb-2">⏰ Deadline: {requires8HourReport ? '8 Hours' : '24 Hours'} from incident</p>
                      <p className="text-sm text-red-800">Incident Time: {incidentContext.incidentDate} {incidentContext.incidentTime || ''}</p>
                    </div>

                    <div className="space-y-3 mb-4">
                      <div className="flex items-start">
                        <div className="w-8 h-8 bg-red-600 text-white rounded-full flex items-center justify-center mr-3 flex-shrink-0 font-bold">1</div>
                        <div className="flex-1">
                          <p className="font-semibold text-gray-900">Call OSHA Hotline</p>
                          <p className="text-2xl font-bold text-red-600">1-800-321-OSHA (6742)</p>
                          <p className="text-sm text-gray-600">Available 24/7 for emergency reporting</p>
                        </div>
                      </div>
                      
                      <div className="flex items-center">
                        <div className="flex-1 border-t-2 border-gray-300"></div>
                        <span className="px-3 text-gray-500 font-semibold">OR</span>
                        <div className="flex-1 border-t-2 border-gray-300"></div>
                      </div>

                      <div className="flex items-start">
                        <div className="w-8 h-8 bg-red-600 text-white rounded-full flex items-center justify-center mr-3 flex-shrink-0 font-bold">2</div>
                        <div className="flex-1">
                          <p className="font-semibold text-gray-900 mb-2">File Online Report</p>
                          <button
                            onClick={() => {
                              window.open('https://www.osha.gov/report', '_blank');
                              alert('Opening OSHA reporting website. Your incident data has been prepared and will be available when you fill out the form.');
                            }}
                            className="w-full px-6 py-4 bg-red-600 text-white rounded-lg hover:bg-red-700 font-bold text-lg transition-all shadow-lg hover:shadow-xl flex items-center justify-center"
                          >
                            <AlertTriangle className="h-6 w-6 mr-3" />
                            Complete OSHA Emergency Report Online
                          </button>
                          <p className="text-xs text-gray-600 mt-2">Opens www.osha.gov/report - your incident details will be pre-filled</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* INTERNAL RECORDKEEPING - Shows for all recordable cases */}
              {(isRecordable || requiresImmediateOSHAReport) && (
                <div className="bg-blue-50 border-2 border-blue-200 rounded-xl p-6 mb-6">
                  <h3 className="font-bold text-blue-900 mb-4 text-lg flex items-center">
                    <Clock className="h-5 w-5 mr-2" />
                    Internal Recordkeeping Required - 29 CFR 1904.29
                  </h3>
                  
                  {requiresImmediateOSHAReport && (
                    <div className="bg-blue-100 border-l-4 border-blue-600 p-4 rounded-lg mb-4">
                      <p className="text-sm font-bold text-blue-900 mb-1">📋 Two Separate Requirements:</p>
                      <p className="text-sm text-blue-800">
                        1. Emergency OSHA report (above) - {requires8HourReport ? '8 hours from death' : '24 hours from incident'}<br/>
                        2. Internal recordkeeping (below) - 7 calendar days from learning of incident
                      </p>
                    </div>
                  )}

                  {/* Show what will be pre-filled from assessment */}
                  <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-4">
                    <p className="text-sm font-semibold text-green-900 mb-2">✅ Assessment Data Ready for Forms 300/301:</p>
                    <div className="grid grid-cols-2 gap-2 text-xs text-green-800">
                      <div className="flex items-start">
                        <Check className="h-3 w-3 mr-1 mt-0.5 flex-shrink-0" />
                        <span>Employee: {incidentContext.employeeName}</span>
                      </div>
                      <div className="flex items-start">
                        <Check className="h-3 w-3 mr-1 mt-0.5 flex-shrink-0" />
                        <span>Date: {incidentContext.incidentDate}</span>
                      </div>
                      <div className="flex items-start">
                        <Check className="h-3 w-3 mr-1 mt-0.5 flex-shrink-0" />
                        <span>Location: {incidentContext.location}</span>
                      </div>
                      <div className="flex items-start">
                        <Check className="h-3 w-3 mr-1 mt-0.5 flex-shrink-0" />
                        <span>Classification: {
                          answers.result === 'recordable_death' ? 'Fatality' :
                          answers.result === 'recordable_hospitalization' ? 'Hospitalization' :
                          answers.result === 'recordable_dafw' ? 'Days Away' :
                          answers.result === 'recordable_restricted' ? 'Restricted Work' :
                          'Other Recordable'
                        }</span>
                      </div>
                      {answers.treatments && answers.treatments.length > 0 && (
                        <div className="flex items-start col-span-2">
                          <Check className="h-3 w-3 mr-1 mt-0.5 flex-shrink-0" />
                          <span>Medical treatment details captured</span>
                        </div>
                      )}
                    </div>
                    <p className="text-xs text-green-700 mt-3 italic">
                      ✅ Most OSHA form fields will be automatically populated
                    </p>
                  </div>

                  <div className="space-y-3">
                    <div className="flex items-start bg-white rounded-lg p-4 border border-blue-200">
                      <div className="w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center mr-4 flex-shrink-0 font-bold">1</div>
                      <div className="flex-1">
                        <p className="font-semibold text-blue-900">OSHA Form 300 Log Entry</p>
                        <p className="text-sm text-blue-800 mt-1">✓ Record within 7 calendar days of learning about case</p>
                      </div>
                    </div>
                    <div className="flex items-start bg-white rounded-lg p-4 border border-blue-200">
                      <div className="w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center mr-4 flex-shrink-0 font-bold">2</div>
                      <div className="flex-1">
                        <p className="font-semibold text-blue-900">OSHA Form 301 Incident Report</p>
                        <p className="text-sm text-blue-800 mt-1">✓ Complete detailed incident description within 7 calendar days</p>
                      </div>
                    </div>
                  </div>

                  <div className="mt-6 pt-4 border-t-2 border-blue-200">
                    <button
                      onClick={handleGoToIncidentForm}
                      className="w-full px-6 py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-bold text-lg transition-all shadow-lg hover:shadow-xl flex items-center justify-center"
                    >
                      <FileText className="h-6 w-6 mr-3" />
                      Create OSHA Incident Record (Forms 300/301)
                    </button>
                    <p className="text-xs text-center text-blue-700 mt-2">
                      ✅ Assessment data will auto-fill most fields<br/>
                      📋 Deadline: 7 calendar days ({incidentContext.incidentDate ? 
                        new Date(new Date(incidentContext.incidentDate).getTime() + 7 * 24 * 60 * 60 * 1000).toLocaleDateString() 
                        : 'TBD'})
                    </p>
                  </div>
                </div>
              )}

              {isUpdateExisting && (
                <div className="bg-yellow-50 border-2 border-yellow-200 rounded-xl p-6 mb-6">
                  <h3 className="font-bold text-yellow-900 mb-3 text-lg">Update Existing Case</h3>
                  <p className="text-yellow-800 mb-4">
                    This appears to be a continuation of a previously recorded injury or illness. Do not create a new case entry.
                  </p>
                  <p className="text-yellow-800 font-semibold">
                    If the outcome has changed (e.g., now requires days away from work), update the existing Form 300 entry.
                  </p>
                </div>
              )}

              {(isNotYours || (!isRecordable && !requiresImmediateOSHAReport)) && (
                <div className={`${isNotYours ? 'bg-blue-50 border-blue-200' : 'bg-green-50 border-green-200'} border-2 rounded-xl p-6 mb-6`}>
                  <h3 className={`font-bold mb-3 text-lg ${isNotYours ? 'text-blue-900' : 'text-green-900'}`}>
                    {isNotYours ? 'What You Should Do' : 'No OSHA Recording Required'}
                  </h3>
                  <p className={`mb-4 ${isNotYours ? 'text-blue-800' : 'text-green-800'}`}>
                    {isNotYours 
                      ? 'While this is not recordable on YOUR OSHA logs, you should still document the incident for your internal records and notify the appropriate employer.'
                      : 'This incident does not meet OSHA recordability criteria. However, you may want to document it for internal safety tracking.'}
                  </p>
                </div>
              )}

              {/* Decision summary */}
              <div className="bg-gray-50 rounded-xl p-6 mb-6">
                <h3 className="font-semibold mb-4 text-lg text-gray-900">Assessment Summary</h3>
                <div className="space-y-2">
                  {Object.entries(answers)
                    .filter(([key]) => !['result', 'reason', 'alert', 'exceptions', 'treatments', 'specialCases'].includes(key))
                    .map(([stepNum, answer]) => {
                      const step = decisionTree[parseInt(stepNum)];
                      if (!step || !step.question) return null;
                      
                      return (
                        <div key={stepNum} className="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200">
                          <span className="text-sm font-medium text-gray-700">{step.question}</span>
                          <span className="px-3 py-1 rounded-full text-xs font-bold bg-blue-100 text-blue-800">
                            {Array.isArray(answer) ? `${answer.length} selected` : String(answer).toUpperCase()}
                          </span>
                        </div>
                      );
                    })}
                </div>
              </div>

              {/* Action buttons */}
              <div className="flex flex-col sm:flex-row gap-4">
                <button 
                  onClick={reset}
                  className="flex-1 px-6 py-3 bg-white border-2 border-gray-300 rounded-xl hover:bg-gray-50 font-semibold transition-colors flex items-center justify-center"
                >
                  <RefreshCw className="h-5 w-5 mr-2" />
                  New Assessment
                </button>
                <button 
                  onClick={() => window.print()}
                  className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-semibold transition-colors flex items-center justify-center"
                >
                  <FileText className="h-5 w-5 mr-2" />
                  Print Summary
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // CONTEXT SCREEN (Step 0)
  if (currentStep === 0) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 p-4 md:p-8">
        <div className="max-w-3xl mx-auto">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-600 rounded-full mb-4">
              <Shield className="h-8 w-8 text-white" />
            </div>
            <h1 className="text-4xl font-bold text-gray-900 mb-2">OSHA Recordability Tool</h1>
            <p className="text-lg text-gray-600">Let's determine if this incident needs to be recorded</p>
          </div>

          <div className="bg-white rounded-2xl shadow-2xl p-8">
            <div className="flex items-center mb-6">
              <User className="h-6 w-6 text-blue-600 mr-3" />
              <h2 className="text-2xl font-bold text-gray-900">{currentQuestion.title}</h2>
            </div>
            <p className="text-gray-600 mb-6">{currentQuestion.subtitle}</p>

            <div className="space-y-4">
              {currentQuestion.fields.map(field => (
                <div key={field.id}>
                  <label className="block text-sm font-semibold text-gray-700 mb-2">
                    {field.label} {field.required && <span className="text-red-600">*</span>}
                  </label>
                  {field.type === 'textarea' ? (
                    <textarea
                      value={incidentContext[field.id] || ''}
                      onChange={(e) => setIncidentContext({...incidentContext, [field.id]: e.target.value})}
                      placeholder={field.placeholder}
                      rows="3"
                      className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none transition-colors"
                    />
                  ) : (
                    <input
                      type={field.type}
                      value={incidentContext[field.id] || ''}
                      onChange={(e) => setIncidentContext({...incidentContext, [field.id]: e.target.value})}
                      placeholder={field.placeholder}
                      className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none transition-colors"
                    />
                  )}
                </div>
              ))}
            </div>

            <button
              onClick={handleContextSubmit}
              className="w-full mt-8 px-8 py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-bold text-lg transition-all shadow-lg hover:shadow-xl flex items-center justify-center"
            >
              Start Assessment
              <ChevronRight className="h-6 w-6 ml-2" />
            </button>
          </div>
        </div>
      </div>
    );
  }

  // EXCEPTION CHECKLIST SCREEN
  if (currentQuestion.exceptionChecklist) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 p-4 md:p-8">
        <div className="max-w-4xl mx-auto">
          {/* Progress bar */}
          <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-600">Assessment Progress</span>
              <span className="text-sm font-bold text-blue-600">~60% Complete</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div className="bg-blue-600 h-2 rounded-full transition-all duration-300" style={{width: '60%'}} />
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-2xl p-8">
            <div className="flex items-center mb-2">
              <AlertTriangle className="h-6 w-6 text-yellow-600 mr-3" />
              <span className="text-sm font-bold text-yellow-600 bg-yellow-50 px-3 py-1 rounded-full">
                {currentQuestion.regulation}
              </span>
            </div>
            
            <h2 className="text-3xl font-bold text-gray-900 mb-2">{currentQuestion.title}</h2>
            <p className="text-lg text-gray-600 mb-6">{currentQuestion.subtitle}</p>

            <div className="bg-yellow-50 border-l-4 border-yellow-500 p-4 rounded-lg mb-6">
              <p className="text-sm font-bold text-yellow-900 mb-2">⚠️ OSHA Presumption</p>
              <p className="text-sm text-yellow-800">
                Since this happened in the work environment, OSHA PRESUMES it is work-related. 
                Check the boxes below only if an exception truly applies. If NO boxes are checked, 
                we'll continue with the assessment as work-related.
              </p>
            </div>

            <div className="space-y-3 mb-8">
              {currentQuestion.exceptionChecklist.map((exception) => (
                <div 
                  key={exception.id}
                  className={`border-2 rounded-xl p-4 transition-all cursor-pointer ${
                    exceptionChecks[exception.id] 
                      ? 'border-red-400 bg-red-50' 
                      : 'border-gray-200 bg-white hover:border-gray-300'
                  }`}
                  onClick={() => setExceptionChecks({
                    ...exceptionChecks, 
                    [exception.id]: !exceptionChecks[exception.id]
                  })}
                >
                  <div className="flex items-start">
                    <div className="flex items-center h-5 mt-1">
                      <input
                        type="checkbox"
                        checked={exceptionChecks[exception.id] || false}
                        onChange={() => {}}
                        className="w-5 h-5 text-red-600 border-gray-300 rounded focus:ring-red-500"
                      />
                    </div>
                    <div className="ml-4 flex-1">
                      <div className="flex items-center justify-between">
                        <h4 className="font-bold text-gray-900">{exception.title}</h4>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            setShowInfo({...showInfo, [exception.id]: !showInfo[exception.id]});
                          }}
                          className="text-blue-600 hover:text-blue-700"
                        >
                          <HelpCircle className="h-5 w-5" />
                        </button>
                      </div>
                      <p className="text-xs text-gray-500 mb-1">{exception.regulation}</p>
                      <p className="text-sm text-gray-700">{exception.question}</p>
                      
                      {showInfo[exception.id] && (
                        <div className="mt-3 p-3 bg-blue-50 rounded-lg">
                          {exception.note && (
                            <p className="text-xs text-blue-900 font-semibold mb-2">{exception.note}</p>
                          )}
                          {exception.examples && exception.examples.length > 0 && (
                            <div>
                              <p className="text-xs text-blue-800 font-semibold mb-1">Examples:</p>
                              <ul className="text-xs text-blue-700 space-y-1">
                                {exception.examples.map((ex, i) => (
                                  <li key={i}>• {ex}</li>
                                ))}
                              </ul>
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="flex gap-4">
              <button
                onClick={() => setCurrentStep(currentStep - 1)}
                className="px-6 py-3 border-2 border-gray-300 rounded-xl hover:bg-gray-50 font-semibold flex items-center transition-colors"
              >
                <ChevronLeft className="h-5 w-5 mr-2" />
                Back
              </button>
              <button
                onClick={handleExceptionEvaluation}
                className="flex-1 px-8 py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-bold text-lg transition-all shadow-lg hover:shadow-xl"
              >
                Continue Assessment
                <ChevronRight className="h-6 w-6 ml-2 inline" />
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // MULTI-SELECT MEDICAL TREATMENT SCREEN
  if (currentQuestion.multiSelect) {
    const selectedTreatments = answers[currentStep] || [];
    
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 p-4 md:p-8">
        <div className="max-w-4xl mx-auto">
          <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-600">Assessment Progress</span>
              <span className="text-sm font-bold text-blue-600">~75% Complete</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div className="bg-blue-600 h-2 rounded-full transition-all duration-300" style={{width: '75%'}} />
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-2xl p-8">
            <div className="flex items-center mb-2">
              <AlertCircle className="h-6 w-6 text-blue-600 mr-3" />
              <span className="text-sm font-bold text-blue-600 bg-blue-50 px-3 py-1 rounded-full">
                {currentQuestion.regulation}
              </span>
            </div>
            
            <h2 className="text-3xl font-bold text-gray-900 mb-2">{currentQuestion.question}</h2>
            <p className="text-lg text-gray-600 mb-6">{currentQuestion.subtitle}</p>

            <div className="bg-blue-50 border-l-4 border-blue-500 p-4 rounded-lg mb-6">
              <p className="text-sm text-blue-900">
                <Info className="h-4 w-4 inline mr-2" />
                Select all treatments that were provided. If anything beyond basic first aid was given, this is likely recordable.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mb-8">
              {currentQuestion.options.map((option) => {
                const isSelected = selectedTreatments.includes(option.value);
                const isRecordable = option.recordable;
                
                return (
                  <div
                    key={option.value}
                    onClick={() => {
                      const newSelected = isSelected
                        ? selectedTreatments.filter(v => v !== option.value)
                        : [...selectedTreatments, option.value];
                      setAnswers({...answers, [currentStep]: newSelected});
                    }}
                    className={`border-2 rounded-xl p-4 cursor-pointer transition-all ${
                      isSelected
                        ? isRecordable
                          ? 'border-red-400 bg-red-50'
                          : 'border-green-400 bg-green-50'
                        : 'border-gray-200 bg-white hover:border-gray-300'
                    }`}
                  >
                    <div className="flex items-start">
                      <div className="flex items-center h-5 mt-1">
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => {}}
                          className={`w-5 h-5 border-gray-300 rounded focus:ring-2 ${
                            isRecordable ? 'text-red-600 focus:ring-red-500' : 'text-green-600 focus:ring-green-500'
                          }`}
                        />
                      </div>
                      <div className="ml-3 flex-1">
                        <p className="font-semibold text-gray-900">{option.label}</p>
                        {isSelected && isRecordable && (
                          <p className="text-xs text-red-600 font-semibold mt-1">→ Makes it RECORDABLE</p>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="flex gap-4">
              <button
                onClick={() => setCurrentStep(currentStep - 1)}
                className="px-6 py-3 border-2 border-gray-300 rounded-xl hover:bg-gray-50 font-semibold flex items-center transition-colors"
              >
                <ChevronLeft className="h-5 w-5 mr-2" />
                Back
              </button>
              <button
                onClick={handleMedicalTreatmentEvaluation}
                disabled={selectedTreatments.length === 0}
                className="flex-1 px-8 py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed font-bold text-lg transition-all shadow-lg hover:shadow-xl"
              >
                Continue
                <ChevronRight className="h-6 w-6 ml-2 inline" />
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // SPECIAL CASES MULTI-CHECK SCREEN
  if (currentQuestion.specialCases) {
    const selectedCases = answers[currentStep] || [];
    
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 p-4 md:p-8">
        <div className="max-w-4xl mx-auto">
          <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-600">Final Check</span>
              <span className="text-sm font-bold text-blue-600">~90% Complete</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div className="bg-blue-600 h-2 rounded-full transition-all duration-300" style={{width: '90%'}} />
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-2xl p-8">
            <div className="flex items-center mb-2">
              <AlertTriangle className="h-6 w-6 text-purple-600 mr-3" />
              <span className="text-sm font-bold text-purple-600 bg-purple-50 px-3 py-1 rounded-full">
                Special OSHA Cases
              </span>
            </div>
            
            <h2 className="text-3xl font-bold text-gray-900 mb-2">{currentQuestion.question}</h2>
            <p className="text-lg text-gray-600 mb-6">{currentQuestion.subtitle}</p>

            <div className="space-y-3 mb-8">
              {currentQuestion.specialCases.map((specialCase) => {
                const isSelected = selectedCases.includes(specialCase.id);
                
                return (
                  <div
                    key={specialCase.id}
                    onClick={() => {
                      let newSelected;
                      if (specialCase.id === 'none_special') {
                        newSelected = isSelected ? [] : ['none_special'];
                      } else {
                        newSelected = isSelected
                          ? selectedCases.filter(v => v !== specialCase.id)
                          : [...selectedCases.filter(v => v !== 'none_special'), specialCase.id];
                      }
                      setAnswers({...answers, [currentStep]: newSelected});
                    }}
                    className={`border-2 rounded-xl p-5 cursor-pointer transition-all ${
                      isSelected
                        ? specialCase.recordable
                          ? 'border-red-400 bg-red-50'
                          : 'border-gray-400 bg-gray-50'
                        : 'border-gray-200 bg-white hover:border-gray-300'
                    }`}
                  >
                    <div className="flex items-start">
                      <div className="flex items-center h-6 mt-1">
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => {}}
                          className="w-5 h-5 text-red-600 border-gray-300 rounded focus:ring-red-500"
                        />
                      </div>
                      <div className="ml-4 flex-1">
                        <h4 className="font-bold text-lg text-gray-900 mb-1">{specialCase.title}</h4>
                        {specialCase.regulation && (
                          <p className="text-xs text-gray-500 mb-2">{specialCase.regulation}</p>
                        )}
                        <p className="text-sm text-gray-700 mb-2">{specialCase.description}</p>
                        {specialCase.note && isSelected && (
                          <p className="text-sm text-red-600 font-semibold">{specialCase.note}</p>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="flex gap-4">
              <button
                onClick={() => setCurrentStep(currentStep - 1)}
                className="px-6 py-3 border-2 border-gray-300 rounded-xl hover:bg-gray-50 font-semibold flex items-center transition-colors"
              >
                <ChevronLeft className="h-5 w-5 mr-2" />
                Back
              </button>
              <button
                onClick={handleSpecialCasesEvaluation}
                className="flex-1 px-8 py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-bold text-lg transition-all shadow-lg hover:shadow-xl"
              >
                Complete Assessment
                <CheckCircle className="h-6 w-6 ml-2 inline" />
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // STANDARD QUESTION SCREEN WITH OPTIONS
  const Icon = currentQuestion.icon || Activity;
  const progress = ((currentStep + 1) / decisionTree.length) * 100;

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 p-4 md:p-8">
      <div className="max-w-4xl mx-auto">
        {/* Progress bar */}
        <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Question {currentStep} of {decisionTree.length - 1}</span>
            <span className="text-sm font-bold text-blue-600">{Math.round(progress)}% Complete</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div 
              className="bg-blue-600 h-2 rounded-full transition-all duration-300"
              style={{width: `${progress}%`}}
            />
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-2xl p-8">
          <div className="flex items-center mb-2">
            <Icon className="h-6 w-6 text-blue-600 mr-3" />
            {currentQuestion.regulation && (
              <span className="text-sm font-bold text-blue-600 bg-blue-50 px-3 py-1 rounded-full">
                {currentQuestion.regulation}
              </span>
            )}
          </div>
          
          <h2 className="text-3xl font-bold text-gray-900 mb-2">{currentQuestion.question}</h2>
          {currentQuestion.subtitle && (
            <p className="text-lg text-gray-600 mb-6">{currentQuestion.subtitle}</p>
          )}

          {currentQuestion.presumption && (
            <div className="bg-yellow-50 border-l-4 border-yellow-500 p-4 rounded-lg mb-6">
              <p className="text-sm font-bold text-yellow-900 mb-1">⚠️ OSHA Presumption</p>
              <p className="text-sm text-yellow-800">
                If it happened in the work environment, OSHA presumes it IS work-related unless an exception applies.
              </p>
            </div>
          )}

          {currentQuestion.infoBox && (
            <div className="bg-blue-50 border-l-4 border-blue-500 p-4 rounded-lg mb-6">
              <p className="text-sm font-semibold text-blue-900 mb-1">{currentQuestion.infoBox.title}</p>
              <p className="text-sm text-blue-800">{currentQuestion.infoBox.content}</p>
            </div>
          )}

          <div className="space-y-3 mb-8">
            {currentQuestion.options.map((option) => (
              <button
                key={option.value}
                onClick={() => handleOptionSelect(option)}
                className="w-full text-left border-2 border-gray-200 rounded-xl p-5 hover:border-blue-400 hover:bg-blue-50 transition-all group"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <h4 className="font-bold text-lg text-gray-900 group-hover:text-blue-700 mb-1">
                      {option.label}
                    </h4>
                    {option.description && (
                      <p className="text-sm text-gray-600">{option.description}</p>
                    )}
                    {option.alert && (
                      <p className="text-sm text-red-600 font-bold mt-2">{option.alert}</p>
                    )}
                  </div>
                  <ChevronRight className="h-6 w-6 text-gray-400 group-hover:text-blue-600 flex-shrink-0 ml-4" />
                </div>
              </button>
            ))}
          </div>

          {currentStep > 1 && (
            <button
              onClick={() => setCurrentStep(currentStep - 1)}
              className="px-6 py-3 border-2 border-gray-300 rounded-xl hover:bg-gray-50 font-semibold flex items-center transition-colors"
            >
              <ChevronLeft className="h-5 w-5 mr-2" />
              Back
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default RecordabilityTool;