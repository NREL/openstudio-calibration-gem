// Jenkins pipelines are stored in shared libraries. Please see: https://github.com/NREL/cbci_jenkins_libs
// Note that in the future this will be migrated to github actions
 
@Library('cbci_shared_libs') _

// Build for PR to develop branch only. 
if ((env.CHANGE_ID) && (env.CHANGE_TARGET) ) { // check if set

  openstudio_extension_gems()
    
}

