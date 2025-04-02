import { deleteFile, getFiles } from '@/core/controllers/archivos.controller'
import { FileCard } from './FileCard'
import { createEffect, createSignal, onMount } from 'solid-js'
import type { FileEntity } from '@/types/archivos'
import { BubbleLoadingIcon } from './icons/BubbleLoadingIcon'
import { RefreshIcon } from './icons/RefreshIcon'

const [fetchTrigger, setFetchTrigger] = createSignal(0)

export const FetchButton = () => {
  return (
    <button
      onClick={() => setFetchTrigger(fetchTrigger() + 1)}
      class="text-white/50 hover:text-white/70 p-2 hover:bg-white/5 rounded"
    >
      <RefreshIcon class="w-6 h-6" />
    </button>
  )
}

export const FileList = () => {
  const [fetched, setFetched] = createSignal<boolean>(false)
  const [files, setFiles] = createSignal<FileEntity[]>([])
  const [error, setError] = createSignal<string>('')

  const fetchData = async () => {
    const { data: apiData, error: apiError } = await getFiles()

    setFetched(true)

    if (apiError != null) {
      setError(apiError.message)
      return
    }

    setFiles(apiData)
  }

  createEffect(() => {
    if (fetchTrigger() >= 0) {
      fetchData()
    }
  })

  const deleteItem = (id: number) => async () => {
    const { data: apiData, error: apiError } = await deleteFile({ id })

    if (apiError != null) {
      setError(apiError.message)
      return
    }

    const newData = files().filter((f) => f.id !== id)
    setFiles(newData)
  }

  return (
    <>
      {error().length > 0 && (
        <div class="text-sm text-red-400 font-medium">{error()}</div>
      )}
      {files().length > 0 &&
        files().map((item) => (
          <FileCard file={item} deleteItem={deleteItem(item.id)} />
        ))}
      {!fetched() && (
        <div class="flex flex-col justify-center items-center gap-4 h-full text-white/70">
          <BubbleLoadingIcon class="w-8 h-8" />
          <p>Loading files</p>
        </div>
      )}
    </>
  )
}
